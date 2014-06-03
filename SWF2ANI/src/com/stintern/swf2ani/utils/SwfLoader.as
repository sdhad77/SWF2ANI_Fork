package com.stintern.swf2ani.utils
{
    import com.stintern.swf2ani.utils.datatype.FrameData;
    
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Matrix;
    import flash.system.LoaderContext;
    import flash.text.StaticText;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;

    public class SwfLoader
    {
        //두개의 비트맵데이터가 완전히 일치하지는 않지만, 유사도가 높을 경우 같은 비트맵데이터로 처리하기 위한 비율입니다.
        private const ALLOWABLE_BITMAPDATA_DIFFERENCE_RATE:Number = 0.001;
        
        /**
         * SWF 파일을 로드합니다.  
         * @param path 로드할 SWF 파일(Movie Clip)
         * @param onComplete 파일이 로드되면 결과를 받을 콜백함수 (파라미터: bmp:Bitmap(스프라이트 시트), xml:XML(XML Data ) ) 
         * @param convert 읽어온 swf파일을 무비클립으로 반환할지, 비트맵으로 반환할지 결정하는 변수
         */
        public function loadSWF(path:String, onComplete:Function, convert:Boolean = false):void
        {
            var file:File = findFile(path);
            var fileStream:FileStream = new FileStream();
            fileStream.open(file, FileMode.READ);
            
            var bytes:ByteArray = new ByteArray();
            fileStream.readBytes(bytes);
            
            fileStream.close();
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            
            var loaderContext:LoaderContext = new LoaderContext();
            loaderContext.allowCodeImport = true;
            
            loader.loadBytes(bytes, loaderContext);
            
            function onLoadComplete(event:Event):void
            {
                if(convert)onComplete(convertMovieClip(event.target.content as MovieClip));
                else       onComplete(event.target.content as MovieClip);
                
                loader = null;
                loaderContext = null;
            }
            
            function ioErrorHandler(event:IOErrorEvent):void
            {
                trace("SWF Load error: " + event.target + " _ " + event.text );                  
            }
        }
        
        /**
         * 디바이스 내부 저장소를 확인하여 File 객체를 리턴합니다. 
         */
        private function findFile(path:String):File
        {
            var file:File = File.applicationDirectory.resolvePath(path);
            if( file.exists ) return file;
            
            file = File.applicationStorageDirectory.resolvePath(path);
            if( file.exists ) return file;
            
            return null;
        }
        
        private function convertMovieClip(mc:MovieClip):Array
        {
            var sceneDataVector :Vector.<Vector.<FrameData>> = new Vector.<Vector.<FrameData>>;
            var bmpVector       :Vector.<Bitmap>             = new Vector.<Bitmap>;
            var bmpDictionary   :Dictionary                  = new Dictionary;
            
            var dataVector    :Vector.<FrameData>;
            var tempFrameData  :FrameData;
            var selected       :MovieClip;
            var bmpData        :BitmapData;
            var thisBmpIsNewBmp:Boolean = true;
            
            for(var sceneIdx:uint=1; sceneIdx<=mc.scenes.length; sceneIdx++)
            {
                dataVector = new Vector.<FrameData>;
                
                for( var frameIdx:uint=1; frameIdx<=mc.currentScene.numFrames; ++frameIdx)
                { 
                    mc.gotoAndStop(frameIdx);
                    
                    for(var childIdx:uint = 0; childIdx<mc.numChildren; ++childIdx)
                    {
                        selected = mc.getChildAt(childIdx) as MovieClip;
                        
                        if(mc.getChildAt(childIdx).toString() == "[object StaticText]")
                        {
                            var ooo:StaticText = mc.getChildAt(childIdx) as StaticText;
                            
                            thisBmpIsNewBmp = true;
                            
                            bmpData = new BitmapData (Math.ceil(ooo.width), Math.ceil(ooo.height),true,0x00000000);
                            
                            bmpData.draw(ooo, new Matrix(ooo.transform.matrix.a,0,0,ooo.transform.matrix.d,
                                ooo.x-ooo.transform.pixelBounds.x/ooo.transform.concatenatedMatrix.a*ooo.transform.matrix.a,
                                ooo.y-ooo.transform.pixelBounds.y/ooo.transform.concatenatedMatrix.d*ooo.transform.matrix.d));
                            
                            for(var bmpVectorIdx:uint=0; bmpVectorIdx<bmpVector.length; bmpVectorIdx++)
                            {
                                if(bitmapDataCustomCompare(bmpVector[bmpVectorIdx].bitmapData, bmpData) == true)
                                {
                                    thisBmpIsNewBmp = false;
                                    break;
                                }
                            }
                            
                            tempFrameData = new FrameData;
                            
                            if(thisBmpIsNewBmp == true)
                            {
                                bmpVector.push(new Bitmap(bmpData));
                                bmpDictionary[ooo.toString()] = bmpVector[bmpVector.length - 1];
                            }
                            else bmpDictionary[ooo.toString()] = bmpVector[bmpVectorIdx];
                            
                            tempFrameData.name = ooo.toString();
                            tempFrameData.sceneName = mc.currentScene.name;
                            tempFrameData.frameX = ooo.x;
                            tempFrameData.frameY = ooo.y;
                            tempFrameData.frameWidth = mc.loaderInfo.width;
                            tempFrameData.frameHeight = mc.loaderInfo.height;
                            dataVector.push(tempFrameData);
                        }
                        else
                        {
                            for(var i:uint = 0; i<selected.totalFrames; ++i)
                            {
                                thisBmpIsNewBmp = true;
                                
                                bmpData = new BitmapData (Math.ceil(selected.width), Math.ceil(selected.height),true,0x00000000);
                                
                                bmpData.draw(selected, new Matrix(selected.transform.matrix.a,0,0,selected.transform.matrix.d,
                                    selected.x-selected.transform.pixelBounds.x/selected.transform.concatenatedMatrix.a*selected.transform.matrix.a,
                                    selected.y-selected.transform.pixelBounds.y/selected.transform.concatenatedMatrix.d*selected.transform.matrix.d));
                                
                                for(bmpVectorIdx=0; bmpVectorIdx<bmpVector.length; bmpVectorIdx++)
                                {
                                    if(bitmapDataCustomCompare(bmpVector[bmpVectorIdx].bitmapData, bmpData) == true)
                                    {
                                        thisBmpIsNewBmp = false;
                                        break;
                                    }
                                }
                                
                                tempFrameData = new FrameData;
                                
                                if(thisBmpIsNewBmp == true)
                                {
                                    bmpVector.push(new Bitmap(bmpData));
                                    bmpDictionary[selected.toString() + i.toString()] = bmpVector[bmpVector.length - 1];
                                }
                                else bmpDictionary[selected.toString() + i.toString()] = bmpVector[bmpVectorIdx];
                                
                                tempFrameData.name = selected.toString() + i.toString();
                                tempFrameData.sceneName = mc.currentScene.name;
                                tempFrameData.frameX = selected.transform.pixelBounds.x/selected.transform.concatenatedMatrix.a*selected.transform.matrix.a;
                                tempFrameData.frameY = selected.transform.pixelBounds.y/selected.transform.concatenatedMatrix.d*selected.transform.matrix.d;
                                tempFrameData.frameWidth = mc.loaderInfo.width;
                                tempFrameData.frameHeight = mc.loaderInfo.height;
                                dataVector.push(tempFrameData);
                                
                                selected.nextFrame();
                            }
                        }
                    }
                }
                sceneDataVector.push(dataVector);
                mc.nextScene();
            }
            
            selected = null;
            bmpData = null;
            tempFrameData = null;
            dataVector = null;
            
            return new Array(sceneDataVector, bmpVector, bmpDictionary);
        }
        
        /**
         * 두개의 bitmapData를 비교하는 함수입니다.</br>
         * 두 data의 유사도를 체크하여, 두 data가 사실상 동일하다고 봐도 무방할 경우 두 개의 data가 일치하는 것으로 판단합니다.
         * @param bitmapData1 비교대상 1
         * @param bitmapData2 비교대상 2
         * @return 두 bitmapData가 일치할 경우 true, 일치하지 않을 경우 false
         */
        private function bitmapDataCustomCompare(bitmapData1:BitmapData, bitmapData2:BitmapData):Boolean
        {
            var diffBmpDataObj:Object = bitmapData1.compare(bitmapData2);
            
            // 완전히 일치하는 경우
            if(diffBmpDataObj == 0)
            {
                diffBmpDataObj = null;
                return true;
            }
                // 두 bitmapData의 width, height가 다른 경우
            else if(diffBmpDataObj < 0)
            {
                diffBmpDataObj = null;
                return false;
            }
                // 일치하지 않는 경우
            else
            {
                var diffPixel:int = 0;
                var totalPixel:int = diffBmpDataObj.width * diffBmpDataObj.height;
                
                // 일치하지 않는 픽셀이 몇개인지 조사
                for(var i:int=0; i<diffBmpDataObj.width; i++)
                    for(var j:int=0; j<diffBmpDataObj.height; j++)
                        diffPixel += (diffBmpDataObj.getPixel(i,j) != 0)? 1 : 0;
                
                diffBmpDataObj = null;
                
                //전체 픽셀 중 일치하지 않는 픽셀이 차지하는 비율을 구하고, 사용자가 정의한 값보다 작은 비율일 경우 두 개의 bitmapData는 일치하는것으로 판단합니다.
                if(diffPixel/totalPixel < ALLOWABLE_BITMAPDATA_DIFFERENCE_RATE)
                {
                    return true;
                }
            }
            
            return false;
        }
    }
}