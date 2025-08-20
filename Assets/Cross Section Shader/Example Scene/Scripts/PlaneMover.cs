using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlaneMover : MonoBehaviour {

    private float m_startZ;

    private void Start() {
        m_startZ = transform.position.z;
    }

    private void Update() {
        // Move plane along Z axis
        transform.position = new Vector3(transform.position.x, transform.position.y, m_startZ + Mathf.Sin(Time.realtimeSinceStartup) * 2f);
    }

}
