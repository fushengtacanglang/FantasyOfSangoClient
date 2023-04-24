using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using System.Xml.Serialization;
using UnityEditor;
using UnityEngine;
using UnityEngine.Analytics;

public class BundleEditor
{
    private static string m_BundleTargetPath = Application.streamingAssetsPath;
    private static string ABDATACONFIGPATH = "Assets/Resources/ResData/ABData/ABConfig";
    private static string ABDATAXMLPATH = "Assets/Resources/ResData/ABData/ABXML";
    private static string ABCONFIGPATH = "Assets/Editor/ABConfig.asset";

    //the key is ABName, value is ABPath
    private static Dictionary<string, string> m_AllFileDirDict = new Dictionary<string, string>();
    //filterList
    private static List<string> m_AllFileABPathList = new List<string>();
    //the ABbundle of each Prefab
    private static Dictionary<string, List<string>> m_AllPrefabDirDict = new Dictionary<string, List<string>>();
    //store the Dir
    private static List<string> m_ConfigFileList = new List<string>();

    [MenuItem("Tools/BuildBundle")]
    public static void Build()
    {
        m_ConfigFileList.Clear();
        m_AllFileABPathList.Clear();
        m_AllFileDirDict.Clear();
        m_AllPrefabDirDict.Clear();

        ABConfig abConfig = AssetDatabase.LoadAssetAtPath<ABConfig>(ABCONFIGPATH);

        foreach (ABConfig.FileDirABName fileDir in abConfig.m_AllFileDirAB)
        {
            if (m_AllFileDirDict.ContainsKey(fileDir.ABName))
            {
                Debug.Log("ABName has conflict in the one already exist in Dict");
            }
            else
            {
                m_AllFileDirDict.Add(fileDir.ABName, fileDir.ABPath);
                m_AllFileABPathList.Add(fileDir.ABPath);
                m_ConfigFileList.Add(fileDir.ABPath);
            }
        }
        string[] allStr = AssetDatabase.FindAssets("t:Prefab", abConfig.m_AllPrefabPath.ToArray());
        for (int i = 0; i < allStr.Length; i++)
        {

            string path = AssetDatabase.GUIDToAssetPath(allStr[i]);
            EditorUtility.DisplayProgressBar("FindPrefabProgress", "Prefab: " + path, i / allStr.Length);
            m_ConfigFileList.Add(path);
            if (!IsContainAllFileABPath(path))
            {
                GameObject obj = AssetDatabase.LoadAssetAtPath<GameObject>(path);
                string[] allDepend = AssetDatabase.GetDependencies(path);
                List<string> allDenpendPathList = new List<string>();
                for (int j = 0; j < allDepend.Length; j++)
                {
                    if (!IsContainAllFileABPath(allDepend[j]) && !allDepend[j].EndsWith(".cs"))
                    {
                        m_AllFileABPathList.Add(allDepend[j]);
                        allDenpendPathList.Add(allDepend[j]);
                    }
                }
                if (m_AllPrefabDirDict.ContainsKey(obj.name))
                {
                    Debug.Log("There are already has the same Prefab in Dict, the Prefab is:  " + obj.name);
                }
                else
                {
                    m_AllPrefabDirDict.Add(obj.name, allDenpendPathList);
                }
            }
        }
        foreach (string name in m_AllFileDirDict.Keys)
        {
            SetABName(name, m_AllFileDirDict[name]);
        }
        foreach (string name in m_AllPrefabDirDict.Keys)
        {
            SetABName(name, m_AllPrefabDirDict[name]);
        }

        BuildABBundle();

        string[] oldABNames = AssetDatabase.GetAllAssetBundleNames();
        for (int i = 0; i < oldABNames.Length; i++)
        {
            AssetDatabase.RemoveAssetBundleName(oldABNames[i], true);
            EditorUtility.DisplayProgressBar("RemoveABBundleProgress", "ABName:  " + oldABNames[i], i / oldABNames.Length);
        }
        AssetDatabase.Refresh();
        EditorUtility.ClearProgressBar();
    }

    static void SetABName(string name, string path)
    {
        AssetImporter assetImporter = AssetImporter.GetAtPath(path);
        if (assetImporter == null)
        {
            Debug.Log("This direction has no files, the direction is:   " + path);
        }
        else
        {
            assetImporter.assetBundleName = name;
        }
    }

    static void SetABName(string name, List<string> path)
    {
        for (int i = 0; i < path.Count; i++)
        {
            SetABName(name, path[i]);
        }
    }

    static void BuildABBundle()
    {
        string[] allBundles = AssetDatabase.GetAllAssetBundleNames();
        //the Key is the path, and value is bundle name
        Dictionary<string, string> resPathDict = new Dictionary<string, string>();
        for (int i = 0; i < allBundles.Length; i++)
        {
            string[] allBundlePath = AssetDatabase.GetAssetPathsFromAssetBundle(allBundles[i]);
            for (int j = 0; j < allBundlePath.Length; j++)
            {
                if (allBundlePath[j].EndsWith(".cs"))
                {
                    continue;
                }
                //Debug.Log("This AB Bundle Name is: [ " + allBundles[i]+" ], and the AB Bundle Path is: " + allBundlePath[j]);
                if (IsValidPath(allBundlePath[j]))
                {
                    resPathDict.Add(allBundlePath[j], allBundles[i]);
                }
            }
        }
        DeletOldABBundle();
        WriteData(resPathDict);
        BuildPipeline.BuildAssetBundles(m_BundleTargetPath, BuildAssetBundleOptions.ChunkBasedCompression, EditorUserBuildSettings.activeBuildTarget);
    }

    static void WriteData(Dictionary<string,string> resPathDict)
    {
        AssetBundleConfig config = new AssetBundleConfig();
        config.ABList = new List<ABBase>();
        foreach (string path in resPathDict.Keys)
        {
            ABBase abBase = new ABBase
            {
                Path = path,
                Crc = CRC32.GetCRC32(path),
                ABName = resPathDict[path],
                AssetName = path.Remove(0, path.LastIndexOf("/") + 1),
                ABDependList = new List<string>()
            };
            string[] resDepends = AssetDatabase.GetDependencies(path);
            for (int i = 0; i< resDepends.Length; i++)
            {
                string tempPath = resDepends[i];
                if (tempPath == path || path.EndsWith(".cs"))
                {
                    continue;
                }
                string abName = "";
                if (resPathDict.TryGetValue(tempPath,out abName))
                {
                    if (abName == resPathDict[path])
                    {
                        continue;
                    }
                    if (!abBase.ABDependList.Contains(abName))
                    {
                        abBase.ABDependList.Add(abName);
                    }
                }
            }
            config.ABList.Add(abBase);            
        }

        //Write in XML
        string xmlPath = ABDATAXMLPATH + "/AssetBundleConfig.xml";
        if (File.Exists(xmlPath))
        {
            File.Delete(xmlPath);
        }
        FileStream fileStream = new FileStream(xmlPath, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite);
        StreamWriter writer = new StreamWriter(fileStream,System.Text.Encoding.UTF8);
        XmlSerializer xmlSerializer = new XmlSerializer(config.GetType());
        xmlSerializer.Serialize(writer, config);
        writer.Close();
        fileStream.Close();

        //Write in Binary
        foreach(ABBase abBase in config.ABList)
        {
            abBase.Path = "";
        }
        string bytePath = ABDATACONFIGPATH + "/AssetBundleConfig.bytes";
        FileStream fileStream2 = new FileStream(bytePath, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite);
        BinaryFormatter bf = new BinaryFormatter();
        bf.Serialize(fileStream2, config);
        fileStream2.Close();
    }
    
    static void DeletOldABBundle()
    {
        string[] allBundlesNames = AssetDatabase.GetAllAssetBundleNames();
        DirectoryInfo directoryInfo = new DirectoryInfo(m_BundleTargetPath);
        FileInfo[] fileInfos = directoryInfo.GetFiles("*", SearchOption.AllDirectories);
        for (int i = 0; i < fileInfos.Length; i++)
        {
            if (IsContainABName(fileInfos[i].Name, allBundlesNames) || fileInfos[i].Name.EndsWith(".meta"))
            {
                continue;
            }
            Debug.Log("This AB Bundle has delet or rename:  " + fileInfos[i].Name);
            if (File.Exists(fileInfos[i].FullName))
            {
                File.Delete(fileInfos[i].FullName);
            }
        }
    }

    static bool IsContainABName(string name, string[] strs)
    {
        for (int i = 0; i < strs.Length; i++)
        {
            if (name == strs[i])
            {
                return true;
            }
        }
        return false;
    }

    static bool IsContainAllFileABPath(string path)
    {
        for (int i = 0; i < m_AllFileABPathList.Count; i++)
        {
            if (path == m_AllFileABPathList[i] || (path.Contains(m_AllFileABPathList[i]) && (path.Replace(m_AllFileABPathList[i], "")[0] == '/')))
            {
                return true;
            }
        }
        return false;
    }

    static bool IsValidPath(string path)
    {
        for (int i = 0; i<m_ConfigFileList.Count; i++)
        {
            if (path.Contains(m_ConfigFileList[i]))
            {
                return true;
            }
        }
        return false;
    }
}
