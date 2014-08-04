package com.eyebeyond ;
import haxe.Resource;
import openfl.Assets;
import openfl.display.BitmapData;
using Lambda;

/**
 * ...
 * @author dario
 */
class AndroidResourceLoader
{
	public var androidResourcesBasePath(default,null):String;
	private var _androidResourcesList:Array<String>; //depends only on androidResourcesBasePath, not on _androidConfiguration
	public var androidDeviceConfiguration(default, null) :AndroidDeviceConfiguration; //each time this is changed, need to rebuild _androidResourceBuffer
	private var _loaderBuffer:AndroidResourceLoaderBuffer; //store resolved path to resources in androidresourcebuffer!!!


	public function new(androidResourceBasePath:String="androidres/") 
	{
		this.androidResourcesBasePath = androidResourceBasePath;
		if (androidResourceBasePath.charAt(androidResourceBasePath.length-1) != '/')
		{
			this.androidResourcesBasePath = this.androidResourcesBasePath + "/";
		}
		InitAndroidResourcesList();
		androidDeviceConfiguration = new AndroidDeviceConfiguration();
		_loaderBuffer = new AndroidResourceLoaderBuffer(this);
		androidDeviceConfiguration.registerHandlerSignalConfigurationChanged(_loaderBuffer.reset);	
	}
	public function getLayout(lname:String):Xml
	{
		var resPath = getResourcePath("layout", lname);
		if (resPath == null) return null;
		return getXML(resPath);
	}
	public function getDrawable(lname:String):BitmapData
	{
		var resPath = getResourcePath("drawable", lname);
		if (resPath == null) return null;
		return getBitmapData(resPath);
	}	
	public function getString(id:String):String
	{
		return _loaderBuffer.getString(id);
	}

	public  function hasResource(resourceType:String, resourceName:String):Bool
	{
		return getResourcePath(resourceType, resourceName) != null;
	}
	
	/**
	 * see http://developer.android.com/guide/topics/resources/providing-resources.html#BestMatch 
	 * for explanation of the resource matching algorithm  
	 * @param	resourceType
	 * @param	resourceName
	 * @return
	 */
	public function getResourcePath(resourceType:String, resourceName:String):String
	{
		//TODO instead of running getAllcompatibleresources all the times, I should run it only once, when the android configuration is known, and then use the sublist obtained for further processing (this optimization is also documented in android documentaiton)
		var buffered = _loaderBuffer.getBufferedMatchedResourceName(resourceType, resourceName);
		if (buffered != null) return androidResourcesBasePath+buffered;
		//--Need to sweat a bit for finding the matching resource
		var compatibleResources:Array<String> = getAllCompatibleResources(resourceType, resourceName);
		//-now run the algorithm (defined in android doc) that verify which of the compatible resources gives the best match
		var res = androidDeviceConfiguration.findBestMatchingResource(compatibleResources, resourceType,resourceName);

//		var res:String = androidResourcesBasePath + resourceType + "/" + resourceName;
		
		_loaderBuffer.setBufferedMatchedResourceName(resourceType, resourceName, res);
//		if (hasAsset(res)) return res; //NO NEED to check this, since we start from the list of all existing assets
		return androidResourcesBasePath+res;
}
	

	private function  getAllCompatibleResources(resourceType:String, resourceName:String):Array<String>
	{
		var list = new Array<String>();
		
		//first select resources that match requested resourceType and resourceName
		for (resource in _androidResourcesList)
		{
			var fndpos = resource.indexOf(resourceType);
			if (fndpos != 0) continue; //wrong resource type
			var namestartIdx = resource.indexOf('/', resourceType.length)+1;
			if (resource.indexOf(resourceName, namestartIdx) < 0) continue; //wrong resource name
			list.push(resource);
		}
		
		var reslist = new Array<String>(); //now filter according to current selected android configuration
		for (resource in list)
		{
			if (androidDeviceConfiguration.isCompatibleResource(resourceType, resource))
				reslist.push(resource);
		}		
		return reslist;
	}
	public  function getXML(resourceId:String):Xml {
		var text:String = getText(resourceId);
		var xml:Xml = null;
		if (text != null) {
			xml = Xml.parse(text);
		}
		return xml;
	}
	
	private  function getText(resourceId:String):String {
		var str:String = Resource.getString(resourceId);
		if (str == null) {
			str = Assets.getText(resourceId);
		}
		return str;
	}
	private  function getBitmapData(resourceId:String):BitmapData 
	{
		return Assets.getBitmapData(resourceId);
	}
	
	private  function hasAsset(resouceId:String):Bool
	{
		return Assets.exists(resouceId);
	}	
	
	/**
	 * Scan all resources in the path defined by androidResourcesBasePath
	 * do not store the full path to android resource: store only the <resource_type>/<resource_name>
	 */
	private function InitAndroidResourcesList():Void 
	{
		var reslist = openfl.Assets.list(); //all embedded assets
		_androidResourcesList = new Array<String>();
		for (res in reslist)
		{
			var fndidx = res.indexOf(androidResourcesBasePath);
			if (fndidx != 0) continue;
			_androidResourcesList.push(res.substr(androidResourcesBasePath.length));
		}
	}
	
}