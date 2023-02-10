using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static UnityEngine.Mathf;
using static UnityEngine.Vector3;

public class moving : MonoBehaviour
{
    public Vector3 OffsetPos;

    Vector3 StartPos;
    Vector3 EndPos;

    void Start()
    {
        StartPos = this.transform.position;
        EndPos = this.transform.position + OffsetPos;
    }

    void Update()
    {
        this.transform.position = Lerp(StartPos, EndPos, Sin(Time.time) * 0.5f + 0.5f);
    }

    void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.blue;
        Gizmos.DrawLine(transform.position, transform.position + OffsetPos);
    }
}
