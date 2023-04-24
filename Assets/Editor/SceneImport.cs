using LitJson;
using System.IO;
using UnityEditor;
using UnityEngine;

public class SceneImport : MonoBehaviour
{
    [MenuItem("GameObject/ImprotJSON")]
    public static void LoadSenceJSON()
    {
#if UNITY_EDITOR
        string filepath = Application.dataPath + "/StreamingAssets" + "/IslandSceneJson.txt";
#elif UNITY_IPHONE
	  string filepath = Application.dataPath +"/Raw"+"/IslandSceneJson.txt";
#endif

        StreamReader sr = File.OpenText(filepath);
        string strLine = sr.ReadToEnd();
        JsonData jd = JsonMapper.ToObject(strLine);
        JsonData gameObjectArray = jd["GameObjects"];
        int i, j, k;
        for (i = 0; i < gameObjectArray.Count; i++)
        {
            JsonData senseArray = gameObjectArray[i]["scenes"];
            for (j = 0; j < senseArray.Count; j++)
            {
                string path = (string)senseArray[j]["name"];
                string name = path.Substring(path.LastIndexOf('/') + 1, path.LastIndexOf('.') - path.LastIndexOf('/') - 1);


                if (!name.Equals(Application.loadedLevelName))
                {
                    continue;
                }
                JsonData gameObjects = senseArray[j]["gameObject"];

                for (k = 0; k < gameObjects.Count; k++)
                {
                    string asset = "Assets/Prefab/" + (string)gameObjects[k]["asset"];
                    Vector3 pos = Vector3.zero;
                    Vector3 rot = Vector3.zero;
                    Vector3 sca = Vector3.zero;

                    JsonData position = gameObjects[k]["position"];
                    JsonData rotation = gameObjects[k]["rotation"];
                    JsonData scale = gameObjects[k]["scale"];

                    pos.x = float.Parse((string)position["x"]);
                    pos.y = float.Parse((string)position["y"]);
                    pos.z = float.Parse((string)position["z"]);

                    rot.x = float.Parse((string)rotation["x"]);
                    rot.y = float.Parse((string)rotation["y"]);
                    rot.z = float.Parse((string)rotation["z"]);

                    sca.x = float.Parse((string)scale["x"]);
                    sca.y = float.Parse((string)scale["y"]);
                    sca.z = float.Parse((string)scale["z"]);

                    Debug.Log(asset);
                    Object obj = UnityEditor.AssetDatabase.LoadAssetAtPath(asset, typeof(GameObject));
                    GameObject ob = (GameObject)Instantiate(obj, pos, Quaternion.Euler(rot));
                    ob.transform.localScale = sca;
                    ob.name = obj.name;

                }

            }
        }

    }
}
