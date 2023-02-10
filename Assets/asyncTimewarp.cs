using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Threading;
using UnityEngine;
using System;

public class asyncTimewarp : MonoBehaviour
{
    public GameObject projectorSphere;
    public Projector projector;
    public Camera projectorCamera;
    public Camera cam;

    public RenderTexture targetTexture;
    public RenderTexture targetTextureDepth;

    private Vector2 resolution;

    void Start()
    {
        resolution = new Vector2(Screen.width, Screen.height);
        targetTexture = makeBackbufferTexture();
        targetTextureDepth = makeDepthTexture();
        cam.SetTargetBuffers(targetTexture.colorBuffer, targetTextureDepth.depthBuffer);
    }
    RenderTexture makeBackbufferTexture()
    {
        return new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.Default);
    }
    RenderTexture makeDepthTexture()
    {
        return new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.Depth);
    }


    void setCamera()
    {
        DrawTextureMat.SetFloat("_NearClip", cam.nearClipPlane);
        DrawTextureMat.SetFloat("_FarClip", cam.farClipPlane);
        DrawTextureMat.SetVector("_CameraPos", cam.transform.position);
        DrawTextureMat.SetVector("_CameraForward", cam.transform.forward);
        DrawTextureMat.SetMatrix("_WorldToCameraMatrix", cam.worldToCameraMatrix);
        DrawTextureMat.SetMatrix("_ProjectionMatrix", cam.projectionMatrix);
        

        DrawTextureMat.SetVector("_TopLeft", cam.ViewportPointToRay(new Vector3(0, 1)).direction);
        DrawTextureMat.SetVector("_TopRight", cam.ViewportPointToRay(new Vector3(1, 1)).direction);
        DrawTextureMat.SetVector("_BottomLeft", cam.ViewportPointToRay(new Vector3(0, 0)).direction);
        DrawTextureMat.SetVector("_BottomRight", cam.ViewportPointToRay(new Vector3(1, 0)).direction);

        Debug.DrawRay(cam.transform.position, DrawTextureMat.GetVector("_TopLeft") * 100);
        Debug.DrawRay(cam.transform.position, DrawTextureMat.GetVector("_TopRight") * 100);
        Debug.DrawRay(cam.transform.position, DrawTextureMat.GetVector("_BottomLeft") * 100);
        Debug.DrawRay(cam.transform.position, DrawTextureMat.GetVector("_BottomRight") * 100);
    }

    void setFrozenCamera()
    {
        DrawTextureMat.SetFloat("_NearClip", cam.nearClipPlane);
        DrawTextureMat.SetFloat("_FarClip", cam.farClipPlane);
        DrawTextureMat.SetVector("_FrozenCameraPos", cam.transform.position);
        DrawTextureMat.SetVector("_FrozenCameraForward", cam.transform.forward);
        DrawTextureMat.SetMatrix("_FrozenWorldToCameraMatrix", cam.worldToCameraMatrix);
        DrawTextureMat.SetMatrix("_FrozenProjectionMatrix", cam.projectionMatrix);


        DrawTextureMat.SetVector("_FrozenTopLeft", cam.ViewportPointToRay(new Vector3(0, 1)).direction);
        DrawTextureMat.SetVector("_FrozenTopRight", cam.ViewportPointToRay(new Vector3(1, 1)).direction);
        DrawTextureMat.SetVector("_FrozenBottomLeft", cam.ViewportPointToRay(new Vector3(0, 0)).direction);
        DrawTextureMat.SetVector("_FrozenBottomRight", cam.ViewportPointToRay(new Vector3(1, 0)).direction);

    }

    bool ReprojectMovement = false;
    float accumulatedX = 0;
    float accumulatedY = 0;
    float accumulatedDT;
    float finalDT;
    int SlowFPS = 30;
    void Update()
    {
        DrawTextureMat.SetFloat("_StretchBorders", StretchBorders ? 1.0f : 0.0f);
        DrawTextureMat.SetFloat("_ReprojectMovement", ReprojectMovement ? 1.0f : 0.0f);
        // resize event
        if (resolution.x != Screen.width || resolution.y != Screen.height)
        {
            targetTexture = makeBackbufferTexture();
            targetTextureDepth = makeDepthTexture();
            cam.SetTargetBuffers(targetTexture.colorBuffer, targetTextureDepth.depthBuffer);
            resolution.x = Screen.width;
            resolution.y = Screen.height;
        }
        if (Input.GetKeyDown(KeyCode.Escape) || Input.GetKeyDown(KeyCode.LeftWindows) || Input.GetKeyDown(KeyCode.RightWindows))
        {
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }

        if (Input.GetKeyDown(KeyCode.Alpha1))
            state = 0;
        if (Input.GetKeyDown(KeyCode.Alpha2))
            state = 1;
        if (Input.GetKeyDown(KeyCode.Alpha3))
            state = 2;
        if (Input.GetKeyDown(KeyCode.Alpha4))
            state = 3;


        cam.depthTextureMode = DepthTextureMode.Depth;
        projectorCamera.transform.rotation = cam.transform.rotation;
        projectorCamera.fieldOfView = cam.fieldOfView;

        DrawTextureMat.SetTexture("_ColorTex", targetTexture);
        DrawTextureMat.SetTexture("_DepthTex", targetTextureDepth);

        float MouseX = Input.GetAxis("Mouse X");
        float MouseY = -Input.GetAxis("Mouse Y");

        float MovementX = 0;
        float MovementY = 0;
        if (Input.GetKey(KeyCode.A))
            MovementX--;
        if (Input.GetKey(KeyCode.D))
            MovementX++;
        if (Input.GetKey(KeyCode.W))
            MovementY++;
        if (Input.GetKey(KeyCode.S))
            MovementY--;

        Application.targetFrameRate = -1;
        QualitySettings.vSyncCount = 0;


        accumulatedDT += Time.deltaTime;
        accumulatedX += MouseX;
        accumulatedY += MouseY;
        if (state == 0)
        {
            t = 0;
            setCamera();
            setFrozenCamera();
            if (!Cursor.visible)
            {
                this.transform.parent.transform.Rotate(Vector3.up, MouseX * sensitivity);
                this.transform.Rotate(Vector3.right, MouseY * sensitivity, Space.Self);
                this.transform.parent.Translate(this.transform.parent.forward * MovementY * Time.deltaTime * 5.0f, Space.World);
                this.transform.parent.Translate(this.transform.parent.right * MovementX * Time.deltaTime * 5.0f, Space.World);
            }
            this.GetComponent<Camera>().Render();
            accumulatedDT = 0;
            accumulatedX = 0;
            accumulatedY = 0;
            finalDT = Time.deltaTime;
        }
        else if (state == 1)
        {
            t = 0;
            setCamera();

            if (!Cursor.visible)
            {
                this.transform.parent.transform.Rotate(Vector3.up, MouseX * sensitivity);
                this.transform.Rotate(Vector3.right, MouseY * sensitivity, Space.Self);
                this.transform.parent.Translate(this.transform.parent.forward * MovementY * Time.deltaTime * 5.0f, Space.World);
                this.transform.parent.Translate(this.transform.parent.right * MovementX * Time.deltaTime * 5.0f, Space.World);
            }
            accumulatedDT = 0;
            accumulatedX = 0;
            accumulatedY = 0;
            finalDT = 1;// Time.deltaTime;
        }
        else if (state == 2)
        {
            float DeltaTime60 = 1.0f / SlowFPS;
            t += Time.deltaTime;
            setCamera();
            setFrozenCamera();
            if (t > DeltaTime60)
            {
                t -= DeltaTime60;
                if (!Cursor.visible)
                {
                    this.transform.parent.transform.Rotate(Vector3.up, accumulatedX * sensitivity);
                    this.transform.Rotate(Vector3.right, accumulatedY * sensitivity, Space.Self);
                    this.transform.parent.Translate(this.transform.parent.forward * MovementY * accumulatedDT * 5.0f, Space.World);
                    this.transform.parent.Translate(this.transform.parent.right * MovementX * accumulatedDT * 5.0f, Space.World);
                }
                this.GetComponent<Camera>().Render();
                finalDT = accumulatedDT;
                accumulatedDT = 0;
                accumulatedX = 0;
                accumulatedY = 0;
            }
        }
        else if (state == 3)
        {
            float DeltaTime60 = 1.0f / SlowFPS;
            t += Time.deltaTime;
            setCamera();
            if (!Cursor.visible)
            {
                this.transform.parent.transform.Rotate(Vector3.up, MouseX * sensitivity);
                this.transform.Rotate(Vector3.right, MouseY * sensitivity, Space.Self);
                this.transform.parent.Translate(this.transform.parent.forward * MovementY * Time.deltaTime * 5.0f, Space.World);
                this.transform.parent.Translate(this.transform.parent.right * MovementX * Time.deltaTime * 5.0f, Space.World);
            }
            if (t > DeltaTime60)
            {
                t -= DeltaTime60;
                if (!Cursor.visible)
                {
                    //this.transform.parent.transform.Rotate(Vector3.up, accumulatedX * sensitivity);
                    //this.transform.Rotate(Vector3.right, accumulatedY * sensitivity, Space.Self);
                }
                setFrozenCamera();
                this.GetComponent<Camera>().Render();
                finalDT = accumulatedDT;
                accumulatedDT = 0;
                accumulatedX = 0;
                accumulatedY = 0;
            }
        }
        if(Input.GetKeyDown(KeyCode.Q))
        {
            drawCustom = !drawCustom;
        }
    }
    

    bool drawCustom = false;
    int state = 0;

    float sensitivity = 4.0f;
    float t = 0.0f;
    bool StretchBorders = false;


    public Material DrawTextureMat;
    public Texture testTexture;
    void OnGUI()
    {
        using (var horizontalScope = new GUILayout.VerticalScope("box"))
        {
            GUIStyle boldStyle = new GUIStyle(GUI.skin.label);
            boldStyle.fontStyle = FontStyle.Bold;
            GUIStyle style = new GUIStyle(GUI.skin.label);

            GUILayout.Label("Esc to unlock mouse");
            GUILayout.Label("1 = Render the game at uncapped fps", (state == 0) ? boldStyle : style);
            GUILayout.Label("2 = Freeze rendering new frames and distort using async timewarp", (state == 1) ? boldStyle : style);
            GUILayout.Label("3 = Render the game at " + SlowFPS + " fps", (state == 2) ? boldStyle : style);
            GUILayout.Label("4 = Render the game at " + SlowFPS + " fps, but apply async timewarp", (state == 3) ? boldStyle : style);

            StretchBorders = GUILayout.Toggle(StretchBorders, "Stretch Timewarp borders");
            ReprojectMovement = GUILayout.Toggle(ReprojectMovement, "Include player movement in reprojection");

            GUILayout.Label("Frame Time: " + Math.Round(finalDT * 1000.0f) + "ms " + Math.Round(1.0f / finalDT) + "fps");

            GUILayout.Label("Target FPS: " + SlowFPS);
            SlowFPS = (int)GUILayout.HorizontalSlider((float)SlowFPS, 2, 200);
            GUILayout.Label("Mouse Sensitivity: " + sensitivity);
            sensitivity = GUILayout.HorizontalSlider(sensitivity, 0, 10.0f);


            if (Cursor.visible && GUILayout.Button("Click to control player"))
            {
                Cursor.lockState = CursorLockMode.Locked;
                Cursor.visible = false;
            }
        }
    }
}
