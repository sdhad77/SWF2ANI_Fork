package com.stintern.swf2ani.utils
{
    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.system.LoaderContext;
    import flash.utils.ByteArray;

    public class SWFLoader
    {
        /**
         * SWF 파일을 로드합니다.  
         * @param path 로드할 SWF 파일(Movie Clip)
         * @param onComplete 파일이 로드되면 결과를 받을 콜백함수 (파라미터: bmp:Bitmap(스프라이트 시트), xml:XML(XML Data ) ) 
         * @param onProgress 파일을 로드하는 과정 퍼센트를 반환받는 콜백함수
         */
        public function loadSWF(file:File, onComplete:Function, onProgress:Function = null):void
        {
            var fileStream:FileStream = new FileStream();
            fileStream.open(file, FileMode.READ);
            
            var bytes:ByteArray = new ByteArray();
            fileStream.readBytes(bytes);
            
            fileStream.close();
            
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
            loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            
            var loaderContext:LoaderContext = new LoaderContext();
            loaderContext.allowCodeImport = true;
            
            loader.loadBytes(bytes, loaderContext);
            
            function onLoadComplete(event:Event):void
            {
                var mc:MovieClip = event.target.content as MovieClip;
                
                var swfLoader:Maker = new Maker();
                var result:Array = swfLoader.loadMovieClip(mc);
                
                onComplete( result[0], result[1] );
                
                loader = null;
                loaderContext = null;
                
                swfLoader.clear();
                swfLoader = null;
            }
            
            function onLoadProgress(event:ProgressEvent):void
            {
                if( onProgress != null )
                {
                    onProgress(event.bytesLoaded/event.bytesTotal * 100);
                }
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
            if( file.exists )
                return file;
            
            file = File.applicationStorageDirectory.resolvePath(path);
            if( file.exists )
                return file;
            
            return null;
        }
    }
}