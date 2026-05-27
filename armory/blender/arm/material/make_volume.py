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
    con = {
        'name': context_id,
        'depth_write': True,
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

    frag.add_include('common.inc')

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

    shader_code = """
    vec3 cloudColor = vec3({0}, {1}, {2});
    vec3 emiColor = vec3({4}, {5}, {6});
    float anisotropy = {7};
    vec3 shadowColor = cloudColor * (0.4 + anisotropy * 0.2);
    vec3 L = normalize(vec3(-1.0, 1.0, 0.5));
    float densityAccum = 0.0;
    float transmission = 1.0;
    float finalLight = 0.0;
    vec3 p = localPos - normalize(localPos - (inverse(W) * vec4(eye, 1.0)).xyz) * 0.1;
    for(int i = 0; i < 80; i++) {{
        float nPos_x = p.x * 1.8 + time * 0.03;
        float nPos_y = p.y * 1.8 + time * 0.03;
        float nPos_z = p.z * 1.8 + time * 0.03;
        float p_noise = floor(nPos_x) + floor(nPos_y) * 57.0 + floor(nPos_z) * 113.0;
        vec3 f_noise = fract(vec3(nPos_x, nPos_y, nPos_z));
        f_noise = f_noise * f_noise * (3.0 - 2.0 * f_noise);
        float res_noise = mix(mix(mix(fract(sin(p_noise + 0.0) * 43758.5453), fract(sin(p_noise + 1.0) * 43758.5453), f_noise.x), mix(fract(sin(p_noise + 57.0) * 43758.5453), fract(sin(p_noise + 58.0) * 43758.5453), f_noise.x), f_noise.y), mix(mix(fract(sin(p_noise + 113.0) * 43758.5453), fract(sin(p_noise + 114.0) * 43758.5453), f_noise.x), mix(fract(sin(p_noise + 170.0) * 43758.5453), fract(sin(p_noise + 171.0) * 43758.5453), f_noise.x), f_noise.y), f_noise.z);
        float fbm_val = 0.5000 * res_noise;
        vec3 p_fbm2 = vec3(nPos_x, nPos_y, nPos_z) * 2.02;
        float p_noise2 = floor(p_fbm2.x) + floor(p_fbm2.y) * 57.0 + floor(p_fbm2.z) * 113.0;
        vec3 f_noise2 = fract(p_fbm2);
        f_noise2 = f_noise2 * f_noise2 * (3.0 - 2.0 * f_noise2);
        float res_noise2 = mix(mix(mix(fract(sin(p_noise2 + 0.0) * 43758.5453), fract(sin(p_noise2 + 1.0) * 43758.5453), f_noise2.x), mix(fract(sin(p_noise2 + 57.0) * 43758.5453), fract(sin(p_noise2 + 58.0) * 43758.5453), f_noise2.x), f_noise2.y), mix(mix(fract(sin(p_noise2 + 113.0) * 43758.5453), fract(sin(p_noise2 + 114.0) * 43758.5453), f_noise2.x), mix(fract(sin(p_noise2 + 170.0) * 43758.5453), fract(sin(p_noise2 + 171.0) * 43758.5453), f_noise2.x), f_noise2.y), f_noise2.z);
        fbm_val += 0.2500 * res_noise2;
        vec3 p_fbm3 = p_fbm2 * 2.03;
        float p_noise3 = floor(p_fbm3.x) + floor(p_fbm3.y) * 57.0 + floor(p_fbm3.z) * 113.0;
        vec3 f_noise3 = fract(p_fbm3);
        f_noise3 = f_noise3 * f_noise3 * (3.0 - 2.0 * f_noise3);
        float res_noise3 = mix(mix(mix(fract(sin(p_noise3 + 0.0) * 43758.5453), fract(sin(p_noise3 + 1.0) * 43758.5453), f_noise3.x), mix(fract(sin(p_noise3 + 57.0) * 43758.5453), fract(sin(p_noise3 + 58.0) * 43758.5453), f_noise3.x), f_noise3.y), mix(mix(fract(sin(p_noise3 + 113.0) * 43758.5453), fract(sin(p_noise3 + 114.0) * 43758.5453), f_noise3.x), mix(fract(sin(p_noise3 + 170.0) * 43758.5453), fract(sin(p_noise3 + 171.0) * 43758.5453), f_noise3.x), f_noise3.y), f_noise3.z);
        fbm_val += 0.1250 * res_noise3;
        float d = smoothstep(0.4, 0.6, fbm_val) * {3};
        if (d > 0.01) {{
            float lightAccum = 0.0;
            vec3 lightP = p;
            for(int j = 0; j < 6; j++) {{
                lightP += L * 0.12;
                float lp_x = lightP.x * 1.8 + time * 0.03;
                float lp_y = lightP.y * 1.8 + time * 0.03;
                float lp_z = lightP.z * 1.8 + time * 0.03;
                float l_p_noise = floor(lp_x) + floor(lp_y) * 57.0 + floor(lp_z) * 113.0;
                vec3 l_f_noise = fract(vec3(lp_x, lp_y, lp_z));
                l_f_noise = l_f_noise * l_f_noise * (3.0 - 2.0 * l_f_noise);
                float l_res_noise = mix(mix(mix(fract(sin(l_p_noise + 0.0) * 43758.5453), fract(sin(l_p_noise + 1.0) * 43758.5453), l_f_noise.x), mix(fract(sin(l_p_noise + 57.0) * 43758.5453), fract(sin(l_p_noise + 58.0) * 43758.5453), l_f_noise.x), l_f_noise.y), mix(mix(fract(sin(l_p_noise + 113.0) * 43758.5453), fract(sin(l_p_noise + 114.0) * 43758.5453), l_f_noise.x), mix(fract(sin(l_p_noise + 170.0) * 43758.5453), fract(sin(l_p_noise + 171.0) * 43758.5453), l_f_noise.x), l_f_noise.y), l_f_noise.z);
                float l_fbm_val = 0.5000 * l_res_noise;
                vec3 l_p_fbm2 = vec3(lp_x, lp_y, lp_z) * 2.02;
                float l_p_noise2 = floor(l_p_fbm2.x) + floor(l_p_fbm2.y) * 57.0 + floor(l_p_fbm2.z) * 113.0;
                vec3 l_f_noise2 = fract(l_p_fbm2);
                l_f_noise2 = l_f_noise2 * l_f_noise2 * (3.0 - 2.0 * l_f_noise2);
                float l_res_noise2 = mix(mix(mix(fract(sin(l_p_noise2 + 0.0) * 43758.5453), fract(sin(l_p_noise2 + 1.0) * 43758.5453), l_f_noise2.x), mix(fract(sin(l_p_noise2 + 57.0) * 43758.5453), fract(sin(l_p_noise2 + 58.0) * 43758.5453), l_f_noise2.x), l_f_noise2.y), mix(mix(fract(sin(l_p_noise2 + 113.0) * 43758.5453), fract(sin(l_p_noise2 + 114.0) * 43758.5453), l_f_noise2.x), mix(fract(sin(l_p_noise2 + 170.0) * 43758.5453), fract(sin(l_p_noise2 + 171.0) * 43758.5453), l_f_noise2.x), l_f_noise2.y), l_f_noise2.z);
                l_fbm_val += 0.2500 * l_res_noise2;
                vec3 l_p_fbm3 = l_p_fbm2 * 2.03;
                float l_p_noise3 = floor(l_p_fbm3.x) + floor(l_p_fbm3.y) * 57.0 + floor(l_p_fbm3.z) * 113.0;
                vec3 l_f_noise3 = fract(l_p_fbm3);
                l_f_noise3 = l_f_noise3 * l_f_noise3 * (3.0 - 2.0 * l_f_noise3);
                float l_res_noise3 = mix(mix(mix(fract(sin(l_p_noise3 + 0.0) * 43758.5453), fract(sin(l_p_noise3 + 1.0) * 43758.5453), l_f_noise3.x), mix(fract(sin(l_p_noise3 + 57.0) * 43758.5453), fract(sin(l_p_noise3 + 58.0) * 43758.5453), l_f_noise3.x), l_f_noise3.y), mix(mix(fract(sin(l_p_noise3 + 113.0) * 43758.5453), fract(sin(l_p_noise3 + 114.0) * 43758.5453), l_f_noise3.x), mix(fract(sin(l_p_noise3 + 170.0) * 43758.5453), fract(sin(l_p_noise3 + 171.0) * 43758.5453), l_f_noise3.x), l_f_noise3.y), l_f_noise3.z);
                l_fbm_val += 0.1250 * l_res_noise3;
                lightAccum += smoothstep(0.4, 0.6, l_fbm_val);
            }}
            float shadow = 0.1 + exp(-lightAccum * 1.5) * 0.9;
            finalLight += d * transmission * shadow;
            densityAccum += d;
            transmission *= exp(-d * 1.5);
            if (transmission < 0.01) break;
        }}
        p += normalize(localPos - (inverse(W) * vec4(eye, 1.0)).xyz) * 0.03;
        if(length(p) > 2.5) break;
    }}
    float alpha = 1.0 - transmission;
    if (alpha < 0.15) discard;
    fragColor = vec4(mix(shadowColor, cloudColor, clamp(finalLight, 0.0, 1.0)) + emiColor, alpha);
    """.format(color_r, color_g, color_b, density * 0.8, emission_r, emission_g, emission_b, anisotropy)

    frag.write(shader_code)
    frag.add_out('vec4 fragColor')
    
    make_finalize.make(con_volume)

    return con_volume