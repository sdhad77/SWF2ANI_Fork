import flash.display.Bitmap;
import flash.geom.Rectangle;

class FrameData
{
    private var _name:String;
    private var _sceneName:String;
    private var _frameX:Number;
    private var _frameY:Number;
    private var _frameWidth:Number;
    private var _frameHeight:Number;
    private var _rotate:Boolean = false;
    
    public function FrameData()
    {
    }
    
    public function get name():String                { return _name;        }
    public function get sceneName():String           { return _sceneName;   }
    public function get rotate():Boolean             { return _rotate;      }
    public function get frameX():Number              { return _frameX;      }
    public function get frameY():Number              { return _frameY;      }
    public function get frameWidth():Number          { return _frameWidth;  }
    public function get frameHeight():Number         { return _frameHeight; }
    
    public function set name(value:String):void        { _name        = value; }
    public function set sceneName(value:String):void   { _sceneName   = value; }
    public function set rotate(value:Boolean):void     { _rotate      = value; }
    public function set frameX(value:Number):void      { _frameX      = value; }
    public function set frameY(value:Number):void      { _frameY      = value; }
    public function set frameWidth(value:Number):void  { _frameWidth  = value; }
    public function set frameHeight(value:Number):void { _frameHeight = value; }
}

class Node
{
    private var _left:Node;
    private var _right:Node;
    private var _rect:Rect;
    private var _filled:Boolean;
    
    public function Node()
    {
    }
    
    public function get filled():Boolean            {   return _filled;     }
    public function set filled(value:Boolean):void  {   _filled = value;    }
    public function get rect():Rect                 {   return _rect;       }
    public function set rect(value:Rect):void       {   _rect = value;      }
    public function get right():Node                {   return _right;      }
    public function set right(value:Node):void      {   _right = value;     }
    public function get left():Node                 {   return _left;       }
    public function set left(value:Node):void       {   _left = value;      }
}

class Rect extends Rectangle
{	
    public function Rect(x:int, y:int, width:int, height:int)
    {
        super(x,y,width,height);
    }
    
    /**
     * width와 height를 이용하여 두 사각형의 크기를 비교하고 같을 경우 true 반환
     * @param rc 비교할 Rect
     * @return 두 사각형의 크기가 같으면 true
     */
    public function isSameSize(rc:Rect):Boolean
    {
        if((rc.width == this.width) && (rc.height == this.height)) return true;
        else return false;
    }
    
    /**
     * width와 height를 이용하여 두 사각형의 크기를 비교하고, this의 사각형이 더 클 경우 true 반환
     * @param rc 비교할 Rect
     * @return 호출된(this)의 크기가 더 크면 true
     */
    public function isTooBig(rc:Rect):Boolean
    {
        if((this.width > rc.width) || (this.height > rc.height)) return true;
        else return false;
    }
}

package com.stintern.swf2ani.utils
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;
    import flash.utils.getQualifiedClassName;
    
    public class Maker
    {
        private var _sceneDataVector :Vector.<Vector.<FrameData>>;
        private var _dataVector      :Vector.<FrameData>;
        private var _bmpVector       :Vector.<Bitmap>;
        private var _bmpDictionary   :Dictionary;
        private var _imgBorderLine   :int;       //이미지의 경계선 두께
        private var _imgTotalSize    :int;       //패킹할 이미지들의 전체 사이즈
              
        //이미지 패킹 관련
        private var _packedSpace       :int;    //현재까지 패킹된 공간을 저장함
        private var _packingMaxSpace   :int;    //최대 저장가능한 공간을 저장함
        private var _packingSpaceWidth :int;    //패킹한 이미지들을 저장할 png의 width
        private var _packingSpaceHeight:int;    //패킹한 이미지들을 저장할 png의 height
        
        //스프라이트 시트 이미지, 그에 해당되는 xml 파일
        private var _xml            :XML;
        private var _spriteSheet    :BitmapData;
        
        //스프라이트 시트 크기 예측 관련
        private const SPRITE_SHEET_2_X_2:int       = 4;
        private const SPRITE_SHEET_4_X_4:int       = 16;
        private const SPRITE_SHEET_8_X_8:int       = 64;
        private const SPRITE_SHEET_16_X_16:int     = 256;
        private const SPRITE_SHEET_32_X_32:int     = 1024;
        private const SPRITE_SHEET_64_X_64:int     = 4096;
        private const SPRITE_SHEET_128_X_128:int   = 16384;
        private const SPRITE_SHEET_256_X_256:int   = 65536;
        private const SPRITE_SHEET_512_X_512:int   = 262144;
        private const SPRITE_SHEET_1024_X_1024:int = 1048576;
        private const SPRITE_SHEET_2048_X_2048:int = 4194304;
        private const SPRITE_SHEET_4096_X_4096:int = 16777216;
        
        //두개의 비트맵데이터가 완전히 일치하지는 않지만, 유사도가 높을 경우 같은 비트맵데이터로 처리하기 위한 비율입니다.
        private const ALLOWABLE_BITMAPDATA_DIFFERENCE_RATE:Number = 0.001;
        
        public function Maker()
        {
            init();
        }
        
        private function init():void
        {
            _sceneDataVector = new Vector.<Vector.<FrameData>>;
            _bmpVector       = new Vector.<Bitmap>;
            _bmpDictionary   = new Dictionary;
            _imgBorderLine   = 2;       //경계선을 2px로 설정
            _imgTotalSize    = 0;
            
            _packedSpace = 0;
            _packingMaxSpace = 0;
            
            _packingSpaceWidth = 2;
            _packingSpaceHeight = 2;
            
            _xml = new XML;
        }
        
        public function loadMovieClip(mc:MovieClip):Array
        {
            var tempFrameData:FrameData;
            var thisBmpIsNewBmp:Boolean = true;
            var selected:MovieClip;
            var bmpData:BitmapData;
            
            for(var sceneIdx:uint=1; sceneIdx<=mc.scenes.length; sceneIdx++)
            {
                _dataVector = new Vector.<FrameData>;
                
                for( var frameIdx:uint=1; frameIdx<=mc.currentScene.numFrames; ++frameIdx)
                { 
                    mc.gotoAndStop(frameIdx);
                    
                    for(var childIdx:uint = 0; childIdx<mc.numChildren; ++childIdx)
                    {
                        selected = mc.getChildAt(childIdx) as MovieClip;
                        
                        if(selected.totalFrames == 1)
                        {
                            thisBmpIsNewBmp = true;
                            
                            bmpData = new BitmapData (selected.width, selected.height,true,0x00000000);
                            
                            bmpData.draw(selected, new Matrix(1,0,0,1, 0, 0));
                            
                            for(var bmpVectorIdx:uint=0; bmpVectorIdx<_bmpVector.length; bmpVectorIdx++)
                            {
                                if(bitmapDataCustomCompare(_bmpVector[bmpVectorIdx].bitmapData, bmpData) == true)
                                {
                                    thisBmpIsNewBmp = false;
                                    break;
                                }
                            }
                            
                            tempFrameData = new FrameData;
                            
                            if(thisBmpIsNewBmp == true)
                            {
                                _bmpVector.push(new Bitmap(bmpData));
                                _bmpDictionary[selected.toString()] = _bmpVector[_bmpVector.length - 1];
                            }
                            else _bmpDictionary[selected.toString()] = _bmpVector[bmpVectorIdx];
                            
                            tempFrameData.name = selected.toString();
                            tempFrameData.sceneName = mc.currentScene.name;
                            tempFrameData.frameX = selected.x;
                            tempFrameData.frameY = selected.y;
                            tempFrameData.frameWidth = mc.loaderInfo.width;
                            tempFrameData.frameHeight = mc.loaderInfo.height;
                            _dataVector.push(tempFrameData);
                        }
                        else
                        {
                            for(var i:uint = 0; i<selected.totalFrames; ++i)
                            {
                                thisBmpIsNewBmp = true;
                                
                                bmpData = new BitmapData (mc.loaderInfo.width, mc.loaderInfo.height,true,0x00000000);
                                
                                bmpData.draw(mc, new Matrix(1,0,0,1, 0, 0));
                                
                                for(bmpVectorIdx=0; bmpVectorIdx<_bmpVector.length; bmpVectorIdx++)
                                {
                                    if(bitmapDataCustomCompare(_bmpVector[bmpVectorIdx].bitmapData, bmpData) == true)
                                    {
                                        thisBmpIsNewBmp = false;
                                        break;
                                    }
                                }
                                
                                tempFrameData = new FrameData;
                                
                                if(thisBmpIsNewBmp == true)
                                {
                                    _bmpVector.push(new Bitmap(bmpData));
                                    _bmpDictionary[selected.toString() + i.toString()] = _bmpVector[_bmpVector.length - 1];
                                }
                                else _bmpDictionary[selected.toString() + i.toString()] = _bmpVector[bmpVectorIdx];
                                
                                tempFrameData.name = selected.toString() + i.toString();
                                tempFrameData.sceneName = mc.currentScene.name;
                                tempFrameData.frameX = selected.x;
                                tempFrameData.frameY = selected.y;
                                tempFrameData.frameWidth = mc.loaderInfo.width;
                                tempFrameData.frameHeight = mc.loaderInfo.height;
                                _dataVector.push(tempFrameData);
                                
                                selected.nextFrame();
                            }
                        }
                    }
                }
                _sceneDataVector.push(_dataVector);
                mc.nextScene();
            }
            
            createSpriteSheet();
            
            selected = null;
            bmpData = null;
            tempFrameData = null;
            
            return new Array(new Bitmap(_spriteSheet), _xml);
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
        
        /**
         * swfLoader의 메모리를 해제하는 함수입니다.
         */
        public function clear():void
        {
            if(_sceneDataVector != null)
            {
                while(_sceneDataVector.length > 0)
                {
                    if(_sceneDataVector[0] != null)
                    {
                        while(_sceneDataVector[0].length > 0) _sceneDataVector[0].pop();
                        _sceneDataVector[0] = null;
                    }
                    _sceneDataVector.pop();
                }
            }
            
            if(_dataVector != null)
            {
                while(_dataVector.length > 0) _dataVector.pop();
                _dataVector = null;
            }
            
            for (var key:* in _bmpDictionary) delete _bmpDictionary[key];
            key = null;
            
            if(_bmpVector != null)
            {
                while(_bmpVector.length > 0)
                {
                    _bmpVector[0].bitmapData.dispose();
                    _bmpVector.pop();
                }
                _bmpVector = null;
            }

            if(_spriteSheet != null)
            {
                _spriteSheet = null;
            }
        }
        
        /**
         * 이미지 패킹을 시작하는 함수. 패킹이 완료되면 이미지 출력 함수를 호출함
         */
        private function createSpriteSheet():void
        {
            //이미지를 크기순으로 정렬
            imgSorting();
            
            //이미지 패킹 시작
            imgPacking();
            
            //스프라이트 이미지 생성
            sheetCreate();
            
            //xml 파일 생성
            xmlCreate();
        }
        
        /**
         * 벡터내의 이미지를 크기순으로 정렬. 크기는 width * hegiht의 곱임.
         */
        private function imgSorting():void
        {
            _bmpVector.sort(imgSortingCompareFunc);
            
            function imgSortingCompareFunc(x:Bitmap, y:Bitmap):Number
            {
                return (y.width*y.height) - (x.width*x.height);
            }
        }
        
        /**
         * 이미지 한장으로 합치는 함수.
         */
        private function imgPacking():void
        {
            var rect:Rect;
            var node:Node;
            var packingTreeRoot:Node = new Node;
            
            //sprite sheet의 최종사이즈를 패킹할 이미지 전체의 크기의 합을 기반으로 예측하여 설정하는 함수.
            packingSpacePredictionInit();
            
            packingTreeRoot.rect = new Rect(_imgBorderLine, _imgBorderLine, _packingSpaceWidth, _packingSpaceHeight);
            
            for(var i:int = 0; i < _bmpVector.length; i++)
            {	
                //Sheet에 추가할 이미지의 width,height 세팅
                rect = new Rect(0,0, _bmpVector[i].width + _imgBorderLine, _bmpVector[i].height + _imgBorderLine);   
                
                //트리 탐색과정
                node = Insert_Rect(packingTreeRoot, rect);  
                
                //이미지가 저장될 공간이 있을 경우
                if(node)
                {	
                    //이미지 위치 세팅
                    _bmpVector[i].x = node.rect.x;
                    _bmpVector[i].y = node.rect.y;
                    
                    //패킹된 영역을 나타내기 위함.
                    _packedSpace += _bmpVector[i].width * _bmpVector[i].height;
                }
                    //이미지 저장할 공간이 없을 경우
                else
                {
                    //이미지 확장
                    packingTreeRoot = packingSpaceExtend(packingTreeRoot);
                    
                    //처음부터 다시 탐색하기위해 -1로 설정. for문  완료되면 i++되서 0이됨.
                    i=-1;
                }
            }
            
            //현재는 단순 null 처리지만, 트리 순회하여 자식들 null 시켜줘야 함.
            packingTreeRoot = null;
            rect = null;
            node = null;
        }
        
        /**
         * 현재 노드(root)에 원하는 크기의 Rect(rc)가 들어갈 수 있는지 검사하기 위한 함수
         * @param root 현재 비교중인 노드
         * @param rc root에 원하는 크기의 공간이 있는지 비교하기 위한 Rect
         * @return root의 자식노드 중 작은영역을 가진 left를 호출
         */
        private function Insert_Rect(root:Node, rc:Rect):Node
        {
            //자식이 존재하면 자식노드로 이동
            if(root.left != null) return Insert_Rect(root.left, rc) || Insert_Rect(root.right, rc);
            
            //이미 꽉차있으면 null 리턴
            if(root.filled) return null;
            
            //rc의 크기가 너무 클 경우 null 리턴
            if(rc.isTooBig(root.rect)) return null;
            
            //사이즈가 정확히 일치할 경우.
            if(rc.isSameSize(root.rect))
            {
                root.filled = true;
                return root;
            }
            
            //새로운 자식 생성
            root.left = new Node();
            root.right = new Node();
            
            var dw:int = root.rect.width - rc.width;
            var dh:int = root.rect.height - rc.height;       
            
            if(dw > dh)
            {
                root.left.rect = new Rect(root.rect.x, root.rect.y, rc.width, root.rect.height);
                root.right.rect = new Rect(root.rect.x + rc.width, root.rect.y,dw, root.rect.height);
            }
                
            else 
            {
                root.left.rect = new Rect(root.rect.x, root.rect.y, root.rect.width, rc.height);
                root.right.rect = new Rect(root.rect.x, root.rect.y + rc.height, root.rect.width, dh);
            }        
            
            //영역이 더 작은 left자식으로 이동
            return Insert_Rect(root.left, rc);
        }
        
        /**
         * root node를 입력받아서 가로 세로 2배확장한 후 반환함
         * @param root 이미지패킹의 시작점이 되는 root node
         * @return 확장한 후의 root node
         */
        private function packingSpaceExtend(root:Node):Node
        {
            //가로  세로 2배 증가
            _packingSpaceHeight = _packingSpaceHeight + _packingSpaceHeight;
            _packingSpaceWidth = _packingSpaceWidth + _packingSpaceWidth;
            
            _packingMaxSpace = _packingSpaceWidth * _packingSpaceHeight;
            
            //새로운 탐색을 위해 노드를 새로 설정함
            root = new Node;
            root.rect = new Rect(_imgBorderLine, _imgBorderLine, _packingSpaceWidth, _packingSpaceHeight);
            
            //패킹된 공간도 초기화
            _packedSpace = 0;
            
            return root;
        }
        
        /**
         * sprite sheet의 최종사이즈를 패킹할 이미지 전체의 크기의 합을 기반으로 예측하여 설정하는 함수.
         */
        private function packingSpacePredictionInit():void
        {
            var tempSize:int;
            var tempSheetSpace:int;
            
            if     (_imgTotalSize <= SPRITE_SHEET_2_X_2)      { tempSize = 2;    tempSheetSpace = SPRITE_SHEET_2_X_2;       }
            else if(_imgTotalSize <= SPRITE_SHEET_4_X_4)      { tempSize = 4;    tempSheetSpace = SPRITE_SHEET_4_X_4;       }
            else if(_imgTotalSize <= SPRITE_SHEET_8_X_8)      { tempSize = 8;    tempSheetSpace = SPRITE_SHEET_8_X_8;       }
            else if(_imgTotalSize <= SPRITE_SHEET_16_X_16)    { tempSize = 16;   tempSheetSpace = SPRITE_SHEET_16_X_16;     }
            else if(_imgTotalSize <= SPRITE_SHEET_32_X_32)    { tempSize = 32;   tempSheetSpace = SPRITE_SHEET_32_X_32;     }
            else if(_imgTotalSize <= SPRITE_SHEET_64_X_64)    { tempSize = 64;   tempSheetSpace = SPRITE_SHEET_64_X_64;     }
            else if(_imgTotalSize <= SPRITE_SHEET_128_X_128)  { tempSize = 128;  tempSheetSpace = SPRITE_SHEET_128_X_128;   }
            else if(_imgTotalSize <= SPRITE_SHEET_256_X_256)  { tempSize = 256;  tempSheetSpace = SPRITE_SHEET_256_X_256;   }
            else if(_imgTotalSize <= SPRITE_SHEET_512_X_512)  { tempSize = 512;  tempSheetSpace = SPRITE_SHEET_512_X_512;   }
            else if(_imgTotalSize <= SPRITE_SHEET_1024_X_1024){ tempSize = 1024; tempSheetSpace = SPRITE_SHEET_1024_X_1024; }
            else if(_imgTotalSize <= SPRITE_SHEET_2048_X_2048){ tempSize = 2048; tempSheetSpace = SPRITE_SHEET_2048_X_2048; }
            else 
            {
                tempSize = 4096;
                tempSheetSpace = SPRITE_SHEET_4096_X_4096;
                trace("Sprite Sheet Size is too Big : " + tempSize + "* " + tempSize);
            }
            
            //예측을 기반으로 sheet의 가로 세로길이 설정
            _packingSpaceWidth = tempSize;
            _packingSpaceHeight = tempSize;
            _packingMaxSpace = _packingSpaceWidth * _packingSpaceHeight;
        }
        
        private function sheetCreate():void
        {
            _spriteSheet = new BitmapData (_packingSpaceWidth, _packingSpaceHeight,true,0x00000000);
            
            //이미지 한장에 그리는 중
            for(var i:int = 0; i<_bmpVector.length; i++)
            {
                _spriteSheet.draw(_bmpVector[i], new Matrix(1,0,0,1,_bmpVector[i].x,_bmpVector[i].y));
            }
        }
        
        /**
         * 이미지의 각 데이터를 _xml에 기록하는 함수. 
         */
        private function xmlCreate():void
        {
            _xml = 
                <atlas>
                </atlas>;
            
            for(var j:int=0; j<_sceneDataVector.length; j++)
            {
                for(var i:int=0; i<_sceneDataVector[j].length; i++)
                {
                    var selectedBmp:Bitmap = _bmpDictionary[_sceneDataVector[j][i].name];
                    
                    if(selectedBmp.width%2 == 1) selectedBmp.width += 1;
                    if(selectedBmp.height%2 == 1) selectedBmp.height += 1;
                    
                    var newItem:XML =
                        XML("<atlasItem name =" + "\"" + _sceneDataVector[j][i].sceneName + "_" + i.toString() + ".png" + "\" " + 
                                          "x =" + "\"" + selectedBmp.x                      + "\" " +
                                          "y =" + "\"" + selectedBmp.y                      + "\" " + 
                                      "width =" + "\"" + selectedBmp.width                  + "\" " + 
                                     "height =" + "\"" + selectedBmp.height                 + "\" " + 
                                     "frameX =" + "\"" + _sceneDataVector[j][i].frameX      + "\" " +
                                     "frameY =" + "\"" + _sceneDataVector[j][i].frameY      + "\" " + 
                                 "frameWidth =" + "\"" + _sceneDataVector[j][i].frameWidth  + "\" " + 
                                "frameHeight =" + "\"" + _sceneDataVector[j][i].frameHeight + "\" " + " />");
                    
                    _xml.appendChild(newItem);
                    newItem = null;
                    selectedBmp = null;
                }
            }
        }
    }
}