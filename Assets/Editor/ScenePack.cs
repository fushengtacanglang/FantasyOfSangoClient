using LitJson;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;

public class ScenePack
{
    [MenuItem("GameObject/ExportJSON")]
    static void ExportJSON()
    {
        string filepath = Application.dataPath + @"/StreamingAssets/IslandSceneJson.txt";
        FileInfo t = new FileInfo(filepath);
        if (!File.Exists(filepath))
        {
            File.Delete(filepath);
        }
        StreamWriter sw = t.CreateText();

        StringBuilder sb = new StringBuilder();
        JsonWriter writer = new JsonWriter(sb);
        writer.WriteObjectStart();
        writer.WritePropertyName("GameObjects");
        writer.WriteArrayStart();

        foreach (UnityEditor.EditorBuildSettingsScene S in UnityEditor.EditorBuildSettings.scenes)
        {
            if (S.enabled)
            {
                string name = S.path;
                EditorApplication.OpenScene(name);
                writer.WriteObjectStart();
                writer.WritePropertyName("scenes");
                writer.WriteArrayStart();
                writer.WriteObjectStart();
                writer.WritePropertyName("name");
                writer.Write(name);
                writer.WritePropertyName("gameObject");
                writer.WriteArrayStart();

                foreach (GameObject obj in Object.FindObjectsOfType(typeof(GameObject)))
                {
                    if (obj.transform.parent == null)
                    {
                        writer.WriteObjectStart();
                        writer.WritePropertyName("name");
                        writer.Write(obj.name);
                        writer.WritePropertyName("asset");
                        writer.Write(obj.name + ".prefab");
                        writer.WritePropertyName("position");
                        writer.WriteObjectStart();
                        writer.WritePropertyName("x");
                        writer.Write(obj.transform.position.x.ToString("F5"));
                        writer.WritePropertyName("y");
                        writer.Write(obj.transform.position.y.ToString("F5"));
                        writer.WritePropertyName("z");
                        writer.Write(obj.transform.position.z.ToString("F5"));
                        writer.WriteObjectEnd();

                        writer.WritePropertyName("rotation");
                        writer.WriteObjectStart();
                        writer.WritePropertyName("x");
                        writer.Write(obj.transform.rotation.eulerAngles.x.ToString("F5"));
                        writer.WritePropertyName("y");
                        writer.Write(obj.transform.rotation.eulerAngles.y.ToString("F5"));
                        writer.WritePropertyName("z");
                        writer.Write(obj.transform.rotation.eulerAngles.z.ToString("F5"));
                        writer.WriteObjectEnd();

                        writer.WritePropertyName("scale");
                        writer.WriteObjectStart();
                        writer.WritePropertyName("x");
                        writer.Write(obj.transform.localScale.x.ToString("F5"));
                        writer.WritePropertyName("y");
                        writer.Write(obj.transform.localScale.y.ToString("F5"));
                        writer.WritePropertyName("z");
                        writer.Write(obj.transform.localScale.z.ToString("F5"));
                        writer.WriteObjectEnd();

                        writer.WriteObjectEnd();
                    }
                }

                writer.WriteArrayEnd();
                writer.WriteObjectEnd();
                writer.WriteArrayEnd();
                writer.WriteObjectEnd();
            }
        }
        writer.WriteArrayEnd();
        writer.WriteObjectEnd();

        sw.WriteLine(sb.ToString());
        sw.Close();
        sw.Dispose();
        AssetDatabase.Refresh();
    }
}
