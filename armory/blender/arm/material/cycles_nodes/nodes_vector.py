from typing import Union

import bpy
from mathutils import Euler, Vector

import arm.log
import arm.material.cycles as c
import arm.material.cycles_functions as c_functions
from arm.material.parser_state import ParserState, ParserPass
from arm.material.shader import floatstr, vec3str
import arm.utils as utils

if arm.is_reload(__name__):
    arm.log = arm.reload_module(arm.log)
    c = arm.reload_module(c)
    c_functions = arm.reload_module(c_functions)
    arm.material.parser_state = arm.reload_module(arm.material.parser_state)
    from arm.material.parser_state import ParserState, ParserPass
    arm.material.shader = arm.reload_module(arm.material.shader)
    from arm.material.shader import floatstr, vec3str
    utils = arm.reload_module(utils)
else:
    arm.enable_reload(__name__)


def parse_curvevec(node: bpy.types.ShaderNodeVectorCurve, out_socket: bpy.types.NodeSocket, state: ParserState) -> vec3str:
    fac = c.parse_value_input(node.inputs[0])
    vec = c.parse_vector_input(node.inputs[1])
    curves = node.mapping.curves
    name = c.node_name(node.name)

    res_x = c.vector_curve(name + '0', vec + '.x', curves[0].points)
    res_y = c.vector_curve(name + '1', vec + '.y', curves[1].points)
    res_z = c.vector_curve(name + '2', vec + '.z', curves[2].points)
    
    res_vec = f'vec3({res_x}, {res_y}, {res_z})'

    return f'mix({vec}, {res_vec}, {fac})'


def parse_bump(node: bpy.types.ShaderNodeBump, out_socket: bpy.types.NodeSocket, state: ParserState) -> vec3str:
    if state.curshader.shader_type != 'frag':
        arm.log.warn("Bump node not supported outside of fragment shaders")
        return 'vec3(0.0)'

    # Interpolation strength
    strength = c.parse_value_input(node.inputs[0])
    # Height multiplier
    distance = c.parse_value_input(node.inputs[1])
    height = c.parse_value_input(node.inputs[2])

    state.current_pass = ParserPass.DX_SCREEN_SPACE
    height_dx = c.parse_value_input(node.inputs[2])
    state.current_pass = ParserPass.DY_SCREEN_SPACE
    height_dy = c.parse_value_input(node.inputs[2])
    state.current_pass = ParserPass.REGULAR

    # nor = c.parse_vector_input(node.inputs[3])
    nor = c.parse_vector_input(node.inputs[3]) if node.inputs[3].is_linked else 'n'

    if height_dx != height or height_dy != height:
        tangent = f'{c.dfdx_fine("wposition")} + {nor} * (({height_dx} - {height}) * {distance})'
        bitangent = f'{c.dfdy_fine("wposition")} + {nor} * (({height_dy} - {height}) * {distance})'

        # Cross-product operand order, dFdy is flipped on d3d11
        bitangent_first = utils.get_gapi() == 'direct3d11'

        if node.invert:
            bitangent_first = not bitangent_first

        if bitangent_first:
            # We need to normalize twice, once for the correct "weight" of the strength,
            # once for having a normalized output vector (lerping vectors does not preserve magnitude)
            res = f'normalize(mix({nor}, normalize(cross({bitangent}, {tangent})), {strength}))'
        else:
            res = f'normalize(mix({nor}, normalize(cross({tangent}, {bitangent})), {strength}))'

    else:
        res = nor

    return res


def parse_mapping(node: bpy.types.ShaderNodeMapping, out_socket: bpy.types.NodeSocket, state: ParserState) -> vec3str:
    input_vector = node.inputs[0]
    input_location = node.inputs[1]
    input_rotation = node.inputs[2]
    input_scale = node.inputs[3]

    out = c.parse_vector_input(input_vector) if input_vector.is_linked else c.to_vec3(input_vector.default_value)
    location = c.parse_vector_input(input_location) if input_location.is_linked else c.to_vec3(input_location.default_value)
    rotation = c.parse_vector_input(input_rotation) if input_rotation.is_linked else c.to_vec3(input_rotation.default_value)
    scale = c.parse_vector_input(input_scale) if input_scale.is_linked else c.to_vec3(input_scale.default_value)

    if node.vector_type == 'TEXTURE':
        if input_location.is_linked or any(v != 0.0 for v in input_location.default_value):
            out = f"({out} - {location})"

        if input_rotation.is_linked or any(v != 0.0 for v in input_rotation.default_value):
            var_name = c.node_name(node.name) + "_rotation" + state.get_parser_pass_suffix()
            state.curshader.write(f"mat3 {var_name}X = mat3(1.0, 0.0, 0.0, 0.0, cos({rotation}.x), sin({rotation}.x), 0.0, -sin({rotation}.x), cos({rotation}.x));")
            state.curshader.write(f"mat3 {var_name}Y = mat3(cos({rotation}.y), 0.0, -sin({rotation}.y), 0.0, 1.0, 0.0, sin({rotation}.y), 0.0, cos({rotation}.y));")
            state.curshader.write(f"mat3 {var_name}Z = mat3(cos({rotation}.z), sin({rotation}.z), 0.0, -sin({rotation}.z), cos({rotation}.z), 0.0, 0.0, 0.0, 1.0);")
            out = f"({out} * {var_name}Z * {var_name}Y * {var_name}X)"

        if input_scale.is_linked or any(v != 1.0 for v in input_scale.default_value):
            out = f"({out} / {scale})"

    elif node.vector_type in ['POINT', 'VECTOR', 'NORMAL']:
        if input_scale.is_linked or any(v != 1.0 for v in input_scale.default_value):
            out = f"({out} * {scale})"

        if input_rotation.is_linked or any(v != 0.0 for v in input_rotation.default_value):
            var_name = c.node_name(node.name) + "_rotation" + state.get_parser_pass_suffix()
            state.curshader.write(f"mat3 {var_name}X = mat3(1.0, 0.0, 0.0, 0.0, cos({rotation}.x), -sin({rotation}.x), 0.0, sin({rotation}.x), cos({rotation}.x));")
            state.curshader.write(f"mat3 {var_name}Y = mat3(cos({rotation}.y), 0.0, sin({rotation}.y), 0.0, 1.0, 0.0, -sin({rotation}.y), 0.0, cos({rotation}.y));")
            state.curshader.write(f"mat3 {var_name}Z = mat3(cos({rotation}.z), -sin({rotation}.z), 0.0, sin({rotation}.z), cos({rotation}.z), 0.0, 0.0, 0.0, 1.0);")
            out = f"({out} * {var_name}X * {var_name}Y * {var_name}Z)"

        if node.vector_type == 'POINT':
            if input_location.is_linked or any(v != 0.0 for v in input_location.default_value):
                out = f"({out} + {location})"

        if node.vector_type == 'NORMAL':
            out = f"normalize({out})"

    return out


def parse_normal(node: bpy.types.ShaderNodeNormal, out_socket: bpy.types.NodeSocket, state: ParserState) -> Union[floatstr, vec3str]:
    nor1 = c.to_vec3(node.outputs['Normal'].default_value)

    if out_socket == node.outputs['Normal']:
        return nor1

    elif out_socket == node.outputs['Dot']:
        nor2 = c.parse_vector_input(node.inputs["Normal"])
        return f'dot({nor1}, {nor2})'


def parse_normalmap(node: bpy.types.ShaderNodeNormalMap, out_socket: bpy.types.NodeSocket, state: ParserState) -> vec3str:
    if state.curshader == state.tese:
        return c.parse_vector_input(node.inputs[1])
    else:
        c.parse_normal_map_color_input(node.inputs[1], node.inputs[0], space=node.space)
        return 'n'


def parse_vectortransform(node: bpy.types.ShaderNodeVectorTransform, out_socket: bpy.types.NodeSocket, state: ParserState) -> vec3str:
    vec = c.parse_vector_input(node.inputs[0])
    v_type = node.vector_type
    v_from = node.convert_from
    v_to = node.convert_to

    if v_from == v_to:
        return vec

    shader = state.curshader

    if v_from == 'OBJECT' or v_to == 'OBJECT':
        shader.add_uniform('mat4 W', link='_worldMatrix')
        shader.add_uniform('mat4 IW', link='_inverseWorldMatrix')
    if v_from == 'CAMERA' or v_to == 'CAMERA':
        shader.add_uniform('mat4 V', link='_viewMatrix')
        shader.add_uniform('mat4 IV', link='_inverseViewMatrix')

    w = '1.0' if v_type == 'POINT' else '0.0'
    res = f'vec4({vec}, {w})'

    if v_from == 'OBJECT':
        shader.write('mat4 Wn = W;')
        shader.write('Wn[0] = normalize(Wn[0]);')
        shader.write('Wn[1] = normalize(Wn[1]);')
        shader.write('Wn[2] = normalize(Wn[2]);')
        res = f'(Wn * {res})'
    elif v_from == 'CAMERA':
        res = f'(IV * {res})'

    if v_to == 'OBJECT':
        shader.write('mat4 IWn = IW;')
        shader.write('IWn[0] = normalize(IWn[0]);')
        shader.write('IWn[1] = normalize(IWn[1]);')
        shader.write('IWn[2] = normalize(IWn[2]);')
        res = f'(IWn * {res})'
    elif v_to == 'CAMERA':
        res = f'(V * {res})'

    out = f'({res}).xyz'

    if v_type == 'NORMAL':
        out = f'normalize({out})'

    return out


def parse_displacement(node: bpy.types.ShaderNodeDisplacement, out_socket: bpy.types.NodeSocket, state: ParserState) -> vec3str:
    height = c.parse_value_input(node.inputs[0])
    midlevel = c.parse_value_input(node.inputs[1])
    scale = c.parse_value_input(node.inputs[2])
    nor = c.parse_vector_input(node.inputs[3])
    return f'((vec3({height}) - vec3({midlevel})) * {scale} * {nor})'


def parse_vectorrotate(node: bpy.types.ShaderNodeVectorRotate, out_socket: bpy.types.NodeSocket, state: ParserState) -> vec3str:
    type = node.rotation_type
    input_vector = c.parse_vector_input(node.inputs[0])
    input_center = c.parse_vector_input(node.inputs[1])
    input_axis = c.parse_vector_input(node.inputs[2])
    input_angle = c.parse_value_input(node.inputs[3])
    input_rotation = c.parse_vector_input(node.inputs[4])

    inv = "-1.0" if node.invert else "1.0"
    
    state.curshader.add_function(c_functions.str_rotate_around_axis)

    if type == 'AXIS_ANGLE':
        return f'vec3( (length({input_axis}) > 0.001) ? rotate_around_axis({input_vector} - {input_center}, normalize({input_axis}), {input_angle} * {inv}) + {input_center} : {input_vector} )'
    
    elif type == 'X_AXIS':
        return f'vec3( rotate_around_axis({input_vector} - {input_center}, vec3(1.0, 0.0, 0.0), {input_angle} * {inv}) + {input_center} )'
    
    elif type == 'Y_AXIS':
        return f'vec3( rotate_around_axis({input_vector} - {input_center}, vec3(0.0, 1.0, 0.0), {input_angle} * {inv}) + {input_center} )'
    
    elif type == 'Z_AXIS':
        return f'vec3( rotate_around_axis({input_vector} - {input_center}, vec3(0.0, 0.0, 1.0), {input_angle} * {inv}) + {input_center} )'
    
    elif type == 'EULER_XYZ':
        state.curshader.add_function(c_functions.str_euler_to_mat3)
        rot_val = f'({input_rotation} * {inv})'
        return f'vec3( euler_to_mat3({rot_val}) * ({input_vector} - {input_center}) + {input_center})'

    return f'vec3(0.0, 0.0, 0.0)'
