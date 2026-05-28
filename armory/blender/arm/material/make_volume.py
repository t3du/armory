import arm
import arm.material.make_finalize as make_finalize
import arm.material.make_mesh as make_mesh
import arm.material.mat_state as mat_state
import arm.material.mat_utils as mat_utils

if arm.is_reload(__name__):
    make_finalize = arm.reload_module(make_finalize)
    make_mesh = arm.reload_module(make_mesh)
    mat_state = arm.reload_module(mat_state)
    mat_utils = arm.reload_module(mat_utils)
else:
    arm.enable_reload(__name__)

def make(context_id):

    rpdat = arm.utils.get_rp()
    rid = rpdat.rp_renderer

    con = {
        'name': context_id,
        'depth_write': True if rid == 'Forward' else False,
        'compare_mode': 'less',
        'cull_mode': 'none',
        'blend_source': 'source_alpha',
        'blend_destination': 'inverse_source_alpha',
        'blend_operation': 'add'
    }
    
    con_volume = mat_state.data.add_context(con)
    
    make_mesh.make_base(con_volume, parse_opacity=True)
    
    vert = con_volume.vert
    frag = con_volume.frag

    vert.add_out('vec3 localPos')
    vert.write('localPos = pos.xyz;')

    frag.add_uniform('vec3 eye', link='_cameraPosition')
    frag.add_uniform('float time', link='_time')
    frag.add_uniform('mat4 W', link='_worldMatrix')

    if rid == 'Deferred':
        frag.add_uniform('vec2 screenSize', link='_screenSize')
        frag.add_uniform('sampler2D gbufferD', link='gbufferD')

    color_r, color_g, color_b = 0.5, 0.5, 0.5
    density = 1.0
    emission_r, emission_g, emission_b = 0.0, 0.0, 0.0
    anisotropy = 0.0

    if mat_state.nodes is not None:
        volume_node = None
        for node in mat_state.nodes:
            if node.bl_idname == 'ShaderNodeOutputMaterial':
                if len(node.inputs) > 1 and node.inputs[1].is_linked:
                    volume_node = node.inputs[1].links[0].from_node
                break

        if volume_node is not None:
            if volume_node.bl_idname in ['ShaderNodeVolumeScatter', 'ShaderNodeVolumePrincipled']:
                for input_slot in volume_node.inputs:
                    if input_slot.name == 'Color':
                        color_r = input_slot.default_value[0]
                        color_g = input_slot.default_value[1]
                        color_b = input_slot.default_value[2]
                    elif input_slot.name == 'Density':
                        density = input_slot.default_value
                    elif input_slot.name == 'Emission Color':
                        emission_r = input_slot.default_value[0]
                        emission_g = input_slot.default_value[1]
                        emission_b = input_slot.default_value[2]
                    elif input_slot.name == 'Anisotropy':
                        anisotropy = input_slot.default_value

    str_hash = "\nfloat fhash(float n) { return fract(sin(n) * 43758.5453); }"
    frag.add_function(str_hash)

    str_noise = """
    float noise(vec3 x) {
        vec3 p = floor(x);
        vec3 f = fract(x);
        f = f * f * (3.0 - 2.0 * f);
        float n = p.x + p.y * 57.0 + 113.0 * p.z;
        return mix(mix(mix(fhash(n + 0.0), fhash(n + 1.0), f.x),
                       mix(fhash(n + 57.0), fhash(n + 58.0), f.x), f.y),
                   mix(mix(fhash(n + 113.0), fhash(n + 114.0), f.x),
                       mix(fhash(n + 170.0), fhash(n + 171.0), f.x), f.y), f.z);
    }
    """
    frag.add_function(str_noise)

    str_fbm = """
    float fbm(vec3 p, float t) {
        vec3 p_time = p * 1.8 + t * 0.03;
        float v = 0.5 * noise(p_time);
        v += 0.25 * noise(p_time * 2.02);
        v += 0.125 * noise(p_time * 4.1006);
        return v;
    }
    """
    frag.add_function(str_fbm)

    depth = """
        float sceneDepth = texture(gbufferD, gl_FragCoord.xy / screenSize).r; 
        float depthDiff = sceneDepth - gl_FragCoord.z;
        alpha *= smoothstep(0.0, 0.02, depthDiff);""" if rid == 'Deferred' else ""

    shader_code = """
    vec3 cloudColor = vec3({0}, {1}, {2});
    vec3 emiColor = vec3({4}, {5}, {6});
    float anisotropy = {7};
    vec3 shadowColor = cloudColor * (0.4 + anisotropy * 0.2);
    vec3 L = normalize(vec3(-1.0, 1.0, 0.5));
    float densityAccum = 0.0;
    float transmission = 1.0;
    float finalLight = 0.0;
    
    float jitter = fhash(gl_FragCoord.x + gl_FragCoord.y * 1000.0 + time);
    vec3 viewDir = normalize(localPos - (inverse(W) * vec4(eye, 1.0)).xyz);
    vec3 p = localPos - viewDir * 0.1 + viewDir * jitter * 0.05;
    
    for(int i = 0; i < 32; i++) {{
        float d = smoothstep(0.4, 0.6, fbm(p, time)) * {3};
        if (d > 0.01) {{
            float lightAccum = 0.0;
            vec3 lightP = p;
            for(int j = 0; j < 4; j++) {{
                lightP += L * 0.15;
                lightAccum += smoothstep(0.4, 0.6, fbm(lightP, time));
            }}
            float shadow = 0.1 + exp(-lightAccum * 1.5) * 0.9;
            finalLight += d * transmission * shadow;
            densityAccum += d;
            transmission *= exp(-d * 1.5);
            if (transmission < 0.01) break;
        }}
        p += viewDir * 0.06;
        if(length(p) > 2.5) break;
    }}
    float alpha = 1.0 - transmission;
    {8}
    if (alpha < 0.15) discard;
    fragColor = vec4(mix(shadowColor, cloudColor, clamp(finalLight, 0.0, 1.0)) + emiColor, alpha);
    """.format(color_r, color_g, color_b, density * 0.8, emission_r, emission_g, emission_b, anisotropy, depth)

    frag.write(shader_code)
    frag.add_out('vec4 fragColor')
    
    make_finalize.make(con_volume)

    return con_volume