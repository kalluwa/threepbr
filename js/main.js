//main.js

//变量
var disp;
var scene;
var camera;
var renderer;
var can_width,can_height;

function init(containerId)
{
    /**
     * 1 create container
     */
    can_width = $(window).width()
    can_height = $(window).height()
    
    disp = document.createElement("canvas");

    containerDIV = document.getElementById(containerId);
    containerDIV.appendChild(disp);

    //console.log(disp)
    //set canvas attributes
    disp.width = can_width;
    disp.height = can_height;


    

    /**
     * 2 prepare for THREE
     */
    scene = new THREE.Scene();
    camera = new THREE.PerspectiveCamera(90,can_width/parseFloat(can_height),0.1,1000);
    renderer = new THREE.WebGLRenderer();

    /**
     * 3 initialization
     */
    camera.position.set(0,0,10);
    renderer.setSize(can_width,can_height);

    //put renderer into canvas
    disp.appendChild(renderer.domElement);

}

function render()
{
    renderer.render(scene,camera);
}