package com.stintern.swf2ani.utils
{
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.filesystem.File;
    import flash.net.URLRequest;
    import flash.utils.Dictionary;
    import com.stintern.swf2ani.utils.datatype.FrameData;
    
    /**
     * png파일들을 읽어오는 클래스
     * @author 신동환
     */
    public class PngLoader
    {
        private var _sceneDataVector :Vector.<Vector.<FrameData>>;
        private var _dataVector      :Vector.<FrameData>;
        private var _bmpVector       :Vector.<Bitmap>;
        private var _bmpDictionary   :Dictionary;
        
        //이미지 로딩 관련
        private var _tempFrameData   :FrameData; //파일에서 읽어온 이미지의 데이터를 임시 저장하는 객체
        private var _pathArray       :Array;     //png 파일 경로 저장
        private var _loader          :Loader;    //png 로더
        private var _imgLoadIdx      :int;       //_pathArray의 인덱스
        private var _currentSceneName:String;    //현재 씬 이름
        private var _completedFunc   :Function   //callBack 함수
        
        public function PngLoader()
        {
            init();
        }
        
        /**
         *초기화 하는 함수.
         */
        private function init():void
        {
            _sceneDataVector  = new Vector.<Vector.<FrameData>>;
            _bmpVector        = new Vector.<Bitmap>;
            _bmpDictionary    = new Dictionary;
            
            _pathArray        = new Array;
            _loader           = new Loader;
            _imgLoadIdx       = 0;
            _currentSceneName = null;
            
            _loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderCompleteHandler);
            _loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);	
        }
        
        /**
         * 디렉토리에 있는 png파일의 경로를 Array에 저장하고, 이 Array를 이용하여 이미지를 읽어옴.
         */		
        public function loadPngFolder(file:File, onCompleted:Function):void
        {
            //콜백 함수 저장
            _completedFunc = onCompleted;
            
            //png 파일 경로 탐색
            pngPathSearch(file); 
            
            //찾은 경로를 기반으로 이미지 로딩
            pngLoading();
        }
        
        /**
         * 매개변수로 받은 file의  디렉토리내에 있는 png파일의 경로를 _pathArray에 집어넣음.
         */		
        private function pngPathSearch(file:File):void
        {
            var fileExtension:String;
            var getfiles:Array = file.getDirectoryListing();
            
            for (var i:int = 0; i < getfiles.length; i++) 
            {
                //파일 확장자만 자르기
                fileExtension = getfiles[i].url.substring(getfiles[i].url.lastIndexOf(".") + 1);
                
                //확장자 비교. png이면 push함.
                if(fileExtension == "png") _pathArray.push(getfiles[i]);  
            }
            
            fileExtension = null;
            getfiles = null;
        }
        
        /**
         * loader 사용하여 이미지를 읽어옴.
         */		
        private function pngLoading():void
        {	
            if(_pathArray.length) _loader.load(new URLRequest(_pathArray[_imgLoadIdx].url));
        }
        
        /**
         * png 파일 하나의 로딩이 끝날때마다 호출되는 함수. 이미지 벡터에 읽어온 데이터를 push함.
         * @param e : loader의 이벤트
         */		
        private function loaderCompleteHandler(e:Event):void 
        {
            _bmpVector.push(e.target.content);
            _bmpDictionary[_pathArray[_imgLoadIdx].url.substring(_pathArray[_imgLoadIdx].url.lastIndexOf("/") + 1)] = _bmpVector[_bmpVector.length - 1];
            
            //Image 객체에 필요한 정보들을 _loadedImg에 저장 후 push.
            _tempFrameData = new FrameData;
            _tempFrameData.name = _pathArray[_imgLoadIdx].url.substring(_pathArray[_imgLoadIdx].url.lastIndexOf("/") + 1);
            _tempFrameData.sceneName = _tempFrameData.name.substring(0,_tempFrameData.name.lastIndexOf("_"));
            _tempFrameData.frameX = 0;
            _tempFrameData.frameY = 0;
            _tempFrameData.frameWidth = _bmpVector[_bmpVector.length-1].width;
            _tempFrameData.frameHeight = _bmpVector[_bmpVector.length-1].height;
            
            if(_currentSceneName == null)
            {
                _dataVector = new Vector.<FrameData>;
                _dataVector.push(_tempFrameData);
                _currentSceneName = _tempFrameData.sceneName;
            }
            else if(_currentSceneName == _tempFrameData.sceneName)
            {
                _dataVector.push(_tempFrameData);
            }
            else
            {
                _sceneDataVector.push(_dataVector);
                _dataVector = new Vector.<FrameData>;
                _dataVector.push(_tempFrameData);
                _currentSceneName = _tempFrameData.sceneName;
            }
            
            //모든 이미지 파일을 읽고 push 했을 경우 콜백함수 호출
            if(_imgLoadIdx == _pathArray.length-1)
            {
                _sceneDataVector.push(_dataVector);
                
                clear();
                
                _completedFunc(new Array(_sceneDataVector, _bmpVector, _bmpDictionary));
            }
                //아직 읽을 파일이 남아있을 경우 다시 파일 로딩 실시.
            else
            {
                _imgLoadIdx++;
                pngLoading();
            }
        }
        
        /**
         * 이미지 로딩이 실패할 경우 메모리 해제.
         * @param e : loader의 이벤트
         */		
        private function loaderErrorHandler(e:IOErrorEvent):void
        {
            trace("Error loading image! Here's the error:\n" + e);
            clear();
        }
        
        /**
         * 이미지 로드 과정에서 사용한 객체들 클리어 해줌.
         */
        private function clear():void
        {
            _loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loaderCompleteHandler);
            _loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
            
            while(_pathArray.length) _pathArray.pop();
            
            _dataVector       = null;
            _tempFrameData    = null;
            _pathArray        = null;
            _loader           = null;
            _currentSceneName = null;
        }
    }
}