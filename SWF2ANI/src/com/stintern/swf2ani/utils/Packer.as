package com.stintern.swf2ani.utils
{
    import com.stintern.swf2ani.utils.datatype.FrameData;
    import com.stintern.swf2ani.utils.datatype.Node;
    import com.stintern.swf2ani.utils.datatype.Rect;
    
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.utils.Dictionary;
    
    /**
     * 이미지패킹을 하는 클래스.
     * @author 신동환
     */
    public class Packer
    {
        private var _sceneDataVector :Vector.<Vector.<FrameData>>;
        private var _bmpVector       :Vector.<Bitmap>;
        private var _bmpDictionary   :Dictionary;
        private var _imgBorderLine   :int;         //이미지의 경계선 두께
        private var _imgTotalSize    :int;         //패킹할 이미지들의 전체 사이즈
        
        //이미지 패킹 관련
        private var _packedSpace       :int;    //현재까지 패킹된 공간을 저장함
        private var _packingMaxSpace   :int;    //최대 저장가능한 공간을 저장함
        private var _packingSpaceWidth :int;    //패킹한 이미지들을 저장할 png의 width
        private var _packingSpaceHeight:int;    //패킹한 이미지들을 저장할 png의 height
        private var _isRotate          :Boolean;//현재 패킹중인 이미지가 회전된 이미지인지
        
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
        
        public function Packer()
        {
            init();
        }
        
        /**
         *초기화 하는 함수.
         */
        private function init():void
        {
            _imgBorderLine = 2;       //경계선을 2px로 설정
            _imgTotalSize  = 0;
            
            _packedSpace = 0;
            _packingMaxSpace = 0;
            _packingSpaceWidth = 2;
            _packingSpaceHeight = 2;
        }
        
        /**
         * 이미지 패킹을 시작하는 함수. 패킹이 완료되면 이미지 출력 함수를 호출함
         */
        public function imagePacking(param:Array):Array
        {
            _sceneDataVector = param[0];
            _bmpVector       = param[1];
            _bmpDictionary   = param[2];
            
            //이미지를 크기순으로 정렬
            imgSorting();
            
            //이미지 패킹 시작
            imgPacking();
            
            //스프라이트 이미지 생성
            sheetCreate();
            
            //xml 파일 생성
            xmlCreate();
            
            return (new Array(new Bitmap(_spriteSheet), _xml));
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
            
            packingTreeRoot.rect = new Rect(0, 0, _packingSpaceWidth, _packingSpaceHeight);
            
            for(var i:int = 0; i < _bmpVector.length; i++)
            {	
                //Sheet에 추가할 이미지의 width,height 세팅
                rect = new Rect(0,0, _bmpVector[i].width + _imgBorderLine, _bmpVector[i].height + _imgBorderLine);
                
                if(_bmpVector[i].width == _packingSpaceWidth) rect.width -= _imgBorderLine;
                if(_bmpVector[i].height == _packingSpaceHeight) rect.height -= _imgBorderLine;
                
                //항상 탐색전에 false로.
                _isRotate = false;
                
                //트리 탐색과정
                node = Insert_Rect(packingTreeRoot, rect);
                
                //이미지가 저장될 공간이 있을 경우
                if(node)
                {	
                    if(_isRotate)
                    {
                        //이미지 회전
                        _bmpVector[i].rotation = 90;
                        _bmpVector[i].x = _bmpVector[i].width;
                        
                        //회전시킨거 그림
                        var tempBMD:BitmapData = new BitmapData(_bmpVector[i].width, _bmpVector[i].height,true,0x00000000);
                        tempBMD.draw(_bmpVector[i], _bmpVector[i].transform.matrix);
                        
                        //이미지 다른곳에 그렸으니까 다시 매트릭스 원상복귀
                        _bmpVector[i].rotation = 0;
                        _bmpVector[i].x = 0;
                        
                        //새로 그린 이미지로 연결해줌
                        _bmpVector[i].bitmapData = tempBMD;
                        
                        _bmpVector[i].metaData = new Object;
                        _bmpVector[i].metaData["rotated"] = true;
                    }

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
            if(rc.isTooBig(root.rect))
            {
                var rotateRc:Rect = new Rect(rc.x, rc.y, rc.height, rc.width);
                
                if(rotateRc.isTooBig(root.rect)) return null;
                else
                {
                    rc = rotateRc;
                    _isRotate = true;
                }
            }
            
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
         * root node를 입력받아서 2배확장한 후 반환함
         * @param root 이미지패킹의 시작점이 되는 root node
         * @return 확장한 후의 root node
         */
        private function packingSpaceExtend(root:Node):Node
        {
            //가로 세로 2배 증가
            _packingSpaceWidth = _packingSpaceWidth + _packingSpaceWidth;
            _packingSpaceHeight = _packingSpaceHeight + _packingSpaceHeight;
            
            _packingMaxSpace = _packingSpaceWidth * _packingSpaceHeight;
            
            //새로운 탐색을 위해 노드를 새로 설정함
            root = new Node;
            root.rect = new Rect(0, 0, _packingSpaceWidth, _packingSpaceHeight);
            
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
            
            for(var i:int=0; i< _bmpVector.length; i++) _imgTotalSize += _bmpVector[i].width * _bmpVector[i].height;
            
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
            
            _packingSpaceWidth = _packingSpaceHeight = tempSize;
            _packingMaxSpace = _packingSpaceWidth * _packingSpaceHeight;
        }
        
        private function sheetCreate():void
        {
            _spriteSheet = new BitmapData (_packingSpaceWidth, _packingSpaceHeight,true,0x00000000);
            
            //이미지 한장에 그리는 중
            for(var i:int = 0; i<_bmpVector.length; i++)
            {
                _spriteSheet.draw(_bmpVector[i], _bmpVector[i].transform.matrix);
            }
        }
        
        /**
         * 이미지의 각 데이터를 _xml에 기록하는 함수. 
         */
        private function xmlCreate():void
        {
            _xml = new XML;
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
                    
                    if(selectedBmp.metaData != null && selectedBmp.metaData["rotated"] == true) _sceneDataVector[j][i].rotate = true;
                    
                    if(_sceneDataVector[j][i].sceneName != "") _sceneDataVector[j][i].name = _sceneDataVector[j][i].sceneName + "_" + i.toString() + ".png";
                    
                    var newItem:XML =
                        XML("<SubTexture name =" + "\"" + _sceneDataVector[j][i].name        + "\" " + 
                                           "x =" + "\"" + selectedBmp.x                      + "\" " +
                                           "y =" + "\"" + selectedBmp.y                      + "\" " + 
                                       "width =" + "\"" + selectedBmp.width                  + "\" " + 
                                      "height =" + "\"" + selectedBmp.height                 + "\" " + 
                                      "frameX =" + "\"" + -_sceneDataVector[j][i].frameX     + "\" " +
                                      "frameY =" + "\"" + -_sceneDataVector[j][i].frameY     + "\" " + 
                //                  "frameWidth =" + "\"" + _sceneDataVector[j][i].frameWidth  + "\" " + 
                //                 "frameHeight =" + "\"" + _sceneDataVector[j][i].frameHeight + "\" " +
                                  "frameWidth =" + "\"" + selectedBmp.width                  + "\" " + 
                                 "frameHeight =" + "\"" + selectedBmp.height                 + "\" " +
                                     "rotated =" + "\"" + _sceneDataVector[j][i].rotate      + "\" " +" />");
                    
                    _xml.appendChild(newItem);
                    newItem = null;
                }
            }
        }
        
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
        }
    }
}