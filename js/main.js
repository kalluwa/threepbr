//main.js

//变量
var disp;
var scene;
var camera;
var cam_controls;
var renderer;
var can_width,can_height;

//const
var width_offset_const = 30;
var height_offset_const = 30;

//loader
var loader_gltf;
var shader_mat;
var cube_loader;

//textures
var t_basemap;
var t_mrmap;
var t_normalmap;
var t_roughnessmap;
var t_metalnessmap;
var t_diffuse_cubemap;
var t_specular_cubemap;
var t_brdfLUT;

function init(containerId)
{
    var error = document.getElementById('error');
    var vertDeferred = $.ajax({
        url: './shaders/vs_0.glsl',
        dataType: 'text',
        async: true,
        error: (jqXhr, textStatus, errorThrown) => {
            error.innerHTML += 'Failed to load the vertex shader: ' + errorThrown + '<br>';
        }
    });
    var fragDeferred = $.ajax({
        url: './shaders/ps_0.glsl',
        dataType: 'text',
        async: true,
        error: (jqXhr, textStatus, errorThrown) => {
            error.innerHTML += 'Failed to load the fragment shader: ' + errorThrown + '<br>';
        }
    });
    $.when(vertDeferred, fragDeferred).then((vertSource, fragSource) => {
        renderer = new THREE.WebGLRenderer({antialias: true});
        renderer.context.get
        init_shader(vertSource[0], fragSource[0]);
        init_scene(containerId);
    });

}

function init_shader(vert_src,frag_src)
{
    shader_mat = new THREE.ShaderMaterial({
        vertexShader:vert_src,
        fragmentShader:frag_src,

        uniforms:{
            t_basemap:{type:'t',value:0},
            t_mrmap:{type:'t',value:0},
            t_normalmap:{type:'t',value:0},
            t_metalnessmap:{type:'t',value:0},
            t_roughnessmap:{type:'t',value:0},
            t_brdfLUT:{type:'t',value:0},
            
            //env map
            t_diffuse_cubemap:{type:'t',value:0},
            t_specular_cubemap:{type:'t',value:0},

            v_campos:{type:'v',value:0}
        }
    });
    shader_mat.extensions.derivatives = true;
    console.log("2")
}

function init_scene(containerId){
    /**
     * 1 create container
     */
    can_width = window.innerWidth-width_offset_const;//$(window).width()
    can_height = window.innerHeight-height_offset_const;//$(window).height()

    disp = document.getElementById(containerId);


    //console.log(disp)
    //set canvas attributes
    disp.width = can_width;
    disp.height = can_height;


    

    /**
     * 2 prepare for THREE
     */
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x123456);
    camera = new THREE.PerspectiveCamera(45,can_width/parseFloat(can_height),0.1,1000);
    
    camera.position.set(0,0,-5);
    
    
    console.log("1")
    
    cam_controls = new THREE.OrbitControls(camera,renderer.domElement);

    loader_gltf = new THREE.GLTFLoader();

    /**
     * 3 initialization
     */
    renderer.setSize(can_width,can_height);

    
    load_gltf();

    //env map
    cube_loader = new THREE.CubeTextureLoader();
    cube_loader.load([
        'textures/papermill/diffuse/diffuse_right_0.jpg',
        'textures/papermill/diffuse/diffuse_left_0.jpg',
        'textures/papermill/diffuse/diffuse_top_0.jpg',
        'textures/papermill/diffuse/diffuse_bottom_0.jpg',
        'textures/papermill/diffuse/diffuse_front_0.jpg',
        'textures/papermill/diffuse/diffuse_back_0.jpg'
    ], function (texture) {
        t_diffuse_cubemap = texture;

        shader_mat.uniforms.t_diffuse_cubemap.value = t_diffuse_cubemap;
    });
    cube_loader.load([
        'textures/papermill/specular/specular_right_0.jpg',
        'textures/papermill/specular/specular_left_0.jpg',
        'textures/papermill/specular/specular_top_0.jpg',
        'textures/papermill/specular/specular_bottom_0.jpg',
        'textures/papermill/specular/specular_front_0.jpg',
        'textures/papermill/specular/specular_back_0.jpg'
    ], function (texture) {
        t_specular_cubemap = texture;
        t_specular_cubemap.generateMipmaps = true;
        shader_mat.uniforms.t_specular_cubemap.value = t_specular_cubemap;
    });

    var tex_loader = new THREE.TextureLoader();
    tex_loader.load('textures/brdfLUT.png',function(texture){
        t_brdfLUT = texture;

        shader_mat.uniforms.t_brdfLUT.value = t_brdfLUT;
    });
    //put renderer into canvas
    disp.appendChild(renderer.domElement);

    onInnerEvent()
    
    //render scene
    render();
}

function load_gltf()
{
    var url = "./models/DamagedHelmet/glTF/DamagedHelmet.gltf";
    
    var loadStartTime = performance.now();
    loader_gltf.load( url, function(data) {
        var gltf = data;
        var object = gltf.scene;
        console.log('time elapsed:'+ ( performance.now() - loadStartTime ).toFixed( 2 )+'ms')
        
        var obj3d = object.children[0];

        //提取纹理图像数据
        var extract_mat = obj3d.children[0].children[0].material;
        t_basemap = extract_mat.map;

        t_mrmap = extract_mat.metalnessMap;
        
        t_normalmap = extract_mat.normalMap;

        console.log(obj3d.children[0].children[0].material);
        
        //设置为shader_mat里面的数据
        shader_mat.uniforms.t_basemap.value = t_basemap;//默认贴图
        shader_mat.uniforms.t_mrmap.value = t_mrmap;
        shader_mat.uniforms.t_normalmap.value = t_normalmap;

        //使用shader_mat作为渲染
        obj3d.children[0].children[0].material = shader_mat;

        scene.add( obj3d );
        onSize();
    });

}
function onInnerEvent()
{
    window.addEventListener( 'resize', onSize, false );
}

function render()
{
    renderer.render(scene,camera);

    //update shader params
    shader_mat.uniforms.v_campos.value = camera.position;
    //loop
    requestAnimationFrame(render);
}

function onSize()
{
    can_width = window.innerWidth-width_offset_const;//$(window).width()
    can_height = window.innerHeight-height_offset_const;//$(window).height()

    renderer.setSize(can_width,can_height);
    camera.aspect = can_width / parseFloat(can_height);
    camera.updateProjectionMatrix();

    render();
}
