using UnityEngine;
using System.Collections.Generic;

namespace MeshSlicer {

    [ExecuteInEditMode]
    public class Slicer : MonoBehaviour {

        [SerializeField] private List<Material> m_materials;
        [SerializeField] private Transform m_plane;

        void Update() {
            if (m_materials == null || m_materials.Count == 0) return;

            Matrix4x4 planeMatrix = new Matrix4x4(
                new Vector4(m_plane.right.x, m_plane.forward.x, m_plane.up.x, 0.0f),
                new Vector4(m_plane.right.y, m_plane.forward.y, m_plane.up.y, 0.0f),
                new Vector4(m_plane.right.z, m_plane.forward.z, m_plane.up.z, 0.0f),
                new Vector4(-m_plane.position.x, -m_plane.position.y, -m_plane.position.z, 1.0f)
            );

            foreach (Material mat in m_materials) {
                if (mat == null) continue;
                mat.SetMatrix("_PlaneMatrix", planeMatrix);
            }
        }

    }
}

