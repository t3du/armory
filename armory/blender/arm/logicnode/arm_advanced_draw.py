import bpy
import blf
import gpu
from mathutils import Vector
from gpu_extras.batch import batch_for_shader
from gpu_extras.presets import *
from math import pi, cos, sin

def get_shader_name(name_2d):
    if bpy.app.version >= (4, 0, 0):
        if name_2d == '2D_UNIFORM_COLOR':
            return 'UNIFORM_COLOR'
    return name_2d

def getDpiFactor():
    return getDpi() / 72

def getDpi():
    systemPreferences = bpy.context.preferences.system
    retinaFactor = getattr(systemPreferences, "pixel_size", 1)
    return systemPreferences.dpi * retinaFactor

def getNodeBottomCornerLocations(node):
    region = bpy.context.region
    dpiFactor = getDpiFactor()
    location = node.getViewLocation() * dpiFactor
    dimensions = node.dimensions
    x = location.x
    y = location.y - dimensions.y

    viewToRegion = region.view2d.view_to_region
    leftBottom = Vector(viewToRegion(x, y, clip = False))
    rightBottom = Vector(viewToRegion(x + dimensions.x, y, clip = False))
    return leftBottom, rightBottom

class BlendSpaceGUI:
    def __init__(self, node):
        self.boundary = RectangleWithGrid()
        self.points = Points([])
        self.node = node

    def calculateBoundaries(self):
        dpiFactor = getDpiFactor()
        location = self.node.getViewLocation() * dpiFactor
        dimensions = self.node.dimensions
        x1 = location.x
        x2 = x1 + dimensions.x
        y1 = location.y - dimensions.y
        y2 = y1 - (x2 - x1)

        self.boundary.resetPosition(x1, y1, x2, y2)

    def getHeight(self):
        return self.boundary.height
    
    def setPointSize(self):
        self.node.point_size = self.points.point_size
    
    def setGUIBounds(self):
        self.node.gui_bounds = [self.boundary.x1 + self.boundary.offsetInner, self.boundary.y1 - self.boundary.offsetInner, self.boundary.widthInner]

    def draw(self):
        self.calculateBoundaries()
        self.boundary.draw()
        self.points.calcPoints(self.node.property0, self.node.property1, self.boundary.x1 + self.boundary.offsetInner, self.boundary.y1 - self.boundary.offsetInner, self.boundary.widthInner, self.node.show_numbers)
        self.setGUIBounds()
        self.setPointSize()
        self.points.drawPointCirc()

class Rectangle:
    def __init__(self, x1 = 0, y1 = 0, x2 = 0, y2 = 0):
        self.resetPosition(x1, y1, x2, y2)

    @classmethod
    def fromRegionDimensions(cls, region):
        return cls(0, 0, region.width, region.height)

    def resetPosition(self, x1 = 0, y1 = 0, x2 = 0, y2 = 0):
        self.x1 = float(x1)
        self.y1 = float(y1)
        self.x2 = float(x2)
        self.y2 = float(y2)

    def copy(self):
        return Rectangle(self.x1, self.y1, self.x2, self.y2)

    @property
    def width(self):
        return abs(self.x1 - self.x2)

    @property
    def height(self):
        return abs(self.y1 - self.y2)

    @property
    def left(self):
        return min(self.x1, self.x2)

    @property
    def right(self):
        return max(self.x1, self.x2)

    @property
    def top(self):
        return max(self.y1, self.y2)

    @property
    def bottom(self):
        return min(self.y1, self.y2)

    @property
    def center(self):
        return Vector((self.centerX, self.centerY))

    @property
    def centerX(self):
        return (self.x1 + self.x2) / 2

    @property
    def centerY(self):
        return (self.y1 + self.y2) / 2

    def getInsetRectangle(self, amount):
        return Rectangle(self.left + amount, self.top - amount, self.right - amount, self.bottom + amount)

    def contains(self, point):
        return self.left <= point[0] <= self.right and self.bottom <= point[1] <= self.top

    def draw(self, color = (0.8, 0.8, 0.8, 1.0), borderColor = (0.1, 0.1, 0.1, 1.0), borderThickness = 0):
        locations = (
            (self.x1, self.y1),
            (self.x2, self.y1),
            (self.x1, self.y2),
            (self.x2, self.y2))
        shader = gpu.shader.from_builtin(get_shader_name('2D_UNIFORM_COLOR'))
        batch = batch_for_shader(shader, 'TRI_STRIP', {"pos": locations})

        shader.bind()
        shader.uniform_float("color", color)
        batch.draw(shader)

        if borderThickness == 0: return

        offset = borderThickness // 2
        bWidth = offset * 2 if borderThickness > 0 else 0
        borderLocations = (
            (self.x1 - bWidth, self.y1 + offset), (self.x2 + bWidth, self.y1 + offset),
            (self.x2 + offset, self.y1 + bWidth), (self.x2 + offset, self.y2 - bWidth),
            (self.x2 + bWidth, self.y2 - offset), (self.x1 - bWidth, self.y2 - offset),
            (self.x1 - offset, self.y2 - bWidth), (self.x1 - offset, self.y1 + bWidth))
        batch = batch_for_shader(shader, 'LINES', {"pos": borderLocations})

        shader.bind()
        shader.uniform_float("color", borderColor)
        gpu.state.line_width_set(abs(borderThickness))
        batch.draw(shader)

class Points:
    def __init__(self, points = []):
        self.points = points
        self.point_size = 0.025
        self.width = 0.0
        self.colors = [ (0.4, 0.5, 0.9, 1.0),
                        (1.0, 0.0, 1.0, 1.0),
                        (0.0, 1.0, 1.0, 1.0),
                        (1.0, 1.0, 0.0, 1.0),
                        (0.0, 0.0, 1.0, 1.0),
                        (0.0, 1.0, 0.0, 1.0),
                        (1.0, 0.0, 0.0, 1.0),
                        (0.8, 0.6, 1.0, 1.0),
                        (0.6, 0.8, 1.0, 1.0),
                        (1.0, 0.6, 0.8, 1.0), 
                        (1.0, 1.0, 1.0, 1.0)]
        self.circle_coords = self.circle(0.0, 0.0, self.point_size, 4)
        self.square_coord = self.circle(0.0, 0.0, self.point_size, 5)
        self.visible = []
        self.show_numbers = False
    
    def calcPoints(self, points, visible, x1, y1, width, show_numbers):
        self.width = width
        self.points = []
        self.visible = visible
        self.show_numbers = show_numbers

        for i in range(len(points) // 2):
            point = []
            point.append(x1 + width * points[i * 2])
            point.append(y1 - width + width * points[i * 2 + 1])
            self.points.append(point)

    def reset_circle(self, point):
        return [(coord[0] * self.width + point[0], coord[1] * self.width + point[1]) for coord in self.circle_coords]
    
    def reset_square(self, point):
        return [(coord[0] * self.width + point[0], coord[1] * self.width + point[1]) for coord in self.square_coord]
    
    def circle(self, x, y, radius, segments):
        coords = []
        m = (1.0 / (segments - 1)) * (pi * 2)
        for p in range(segments):
            coords.append((x + cos(m * p) * radius, y + sin(m * p) * radius))
        return coords
    
    def drawPointCirc(self):
        shader = gpu.shader.from_builtin(get_shader_name('2D_UNIFORM_COLOR'))
        
        # Primero dibujamos todas las figuras GPU
        for i in range(len(self.points) - 1):
            if(self.visible[i]):
                pos = self.points[i]
                batch = batch_for_shader(shader, 'TRI_FAN', {"pos": self.reset_circle(pos)})
                shader.bind()
                shader.uniform_float("color", self.colors[i])
                batch.draw(shader)

        square_co = self.reset_square(self.points[len(self.points) - 1])
        batch = batch_for_shader(shader, 'TRI_FAN', {"pos": square_co})
        shader.bind()
        shader.uniform_float("color", self.colors[len(self.points) - 1])
        batch.draw(shader)

        # Al final dibujamos el texto para que no desaparezcan las figuras en 4.0+
        if self.show_numbers:
            for i in range(len(self.points) - 1):
                if(self.visible[i]):
                    pos = self.points[i]
                    col = self.colors[i]
                    blf.color(0, col[0], col[1], col[2], col[3])
                    blf.size(0, int(self.width/10)) 
                    blf.position(0, pos[0], pos[1], 0)
                    blf.draw(0, str(i + 1))

class RectangleWithGrid:
    def __init__(self, x1 = 0, y1 = 0, x2 = 0, y2 = 0):
        self.resetPosition(x1, y1, x2, y2)
        self.numGrids = 21

    def resetPosition(self, x1 = 0, y1 = 0, x2 = 0, y2 = 0):
        self.x1, self.y1, self.x2, self.y2 = float(x1), float(y1), float(x2), float(y2)

    @property
    def width(self): return abs(self.x1 - self.x2)
    @property
    def widthInner(self): return abs(self.width - (2 * self.width/self.numGrids))
    @property
    def offsetInner(self): return abs(self.width/self.numGrids)
    @property
    def height(self): return abs(self.y1 - self.y2)
    @property
    def centerX(self): return (self.x1 + self.x2) / 2
    @property
    def centerY(self): return (self.y1 + self.y2) / 2

    def draw(self, color = (0.5, 0.5, 0.5, 1.0), borderColor = (0.3, 0.3, 0.3, 1.0), gridColor = (0.5, 0.5, 0.5, 1.0), borderThickness = 3, gridLineThickness = 1):
        shader = gpu.shader.from_builtin(get_shader_name('2D_UNIFORM_COLOR'))
        
        # Fondo y Rectángulo interior
        for locs, col in [([(self.x1, self.y1), (self.x2, self.y1), (self.x1, self.y2), (self.x2, self.y2)], color),
                          ([(self.x1 + self.width/self.numGrids, self.y1 - self.height/self.numGrids),
                            (self.x2 - self.width/self.numGrids, self.y1 - self.height/self.numGrids),
                            (self.x1 + self.width/self.numGrids, self.y2 + self.height/self.numGrids),
                            (self.x2 - self.width/self.numGrids, self.y2 + self.height/self.numGrids)], borderColor)]:
            batch = batch_for_shader(shader, 'TRI_STRIP', {"pos": locs})
            shader.bind()
            shader.uniform_float("color", col)
            batch.draw(shader)

        # Bordes y ejes
        borderLocs = [(self.x1, self.y1), (self.x2, self.y1), (self.x2, self.y1), (self.x2, self.y2),
                      (self.x2, self.y2), (self.x1, self.y2), (self.x1, self.y2), (self.x1, self.y1),
                      (self.centerX, self.y1), (self.centerX, self.y2), (self.x1, self.centerY), (self.x2, self.centerY)]
        batch = batch_for_shader(shader, 'LINES', {"pos": borderLocs})
        shader.bind()
        shader.uniform_float("color", gridColor)
        gpu.state.line_width_set(abs(borderThickness))
        batch.draw(shader)

        # Grilla
        offset = (self.x2 - self.x1) / (self.numGrids + 1)
        gridPoints = []
        for l in range(21):
            gridPoints.extend([(self.x1 + (offset * (l + 1)), self.y1), (self.x1 + (offset * (l + 1)), self.y2),
                               (self.x1, self.y1 - (offset * (l + 1))), (self.x2, self.y1 - (offset * (l + 1)))])
        batch = batch_for_shader(shader, 'LINES', {"pos": gridPoints})
        gpu.state.line_width_set(abs(gridLineThickness))
        batch.draw(shader)