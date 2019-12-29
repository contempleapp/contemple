﻿package agf.ui.ctrl{	import flash.display.Sprite;	import agf.ui.ctrl.UiCtrl;		public class WEPopupItem	{		public function WEPopupItem () {}				// Last Selected Item in List		public var sel_id:int = -1;				public var label:String;		public var shortcut:String;				public var iconL:Sprite;		public var iconR:Sprite;		public var items:Array;		public var scrollStart:int=0;		public var data:Object={};		public var selectedItem:WEPopupItem;				public var disabled:Boolean=false;		public var multiSelection:Boolean=false;		private var isStateButton:Boolean=false;		private var isSelected:Boolean=false;				public function set stateButton (v:Boolean) :void { isStateButton = v; }		public function get stateButton () :Boolean { return isStateButton; }				public function set selected (v:Boolean) :void { isSelected = v; }		public function get selected () :Boolean { return isSelected; }				public function assignXml (xo:XML, multiSel:Boolean=false) :void {			multiSelection = multiSel;			var c:XMLList = xo.children();			var L:int = c.length();			for(var i:int=0; i<L; i++) {				if(c[i].children().length() > 0) {					assignXmlNode( c[i], addPopupItem( c[i].@name, (c[i].@shortcut || "")) );				}else{					if((i==0 || i==L-1) && c[i].@name == UiCtrl.KEY_SEPARATOR) continue;					addPopupItem( c[i].@name, (c[i].@shortcut || ""));				}			}		}				public function assignXmlNode (xn:XML, pi:WEPopupItem) :void {			var c:XMLList = xn.children();			var L:int = c.length();			var L2:int;			var atb:XMLList;			var k:int;			var aname:String;						for(var i:int=0; i<L; i++) {				if(c[i].children().length() > 0) {					assignXmlNode( c[i], pi.addPopupItem( c[i].@name, (c[i].@shortcut || "") ) );				}else{					if((i==0 || i==L-1) && c[i].@name == UiCtrl.KEY_SEPARATOR) continue;					pi.addPopupItem( c[i].@name, (c[i].@shortcut || ""));				}			}		}				public function hasChilds () :Boolean {			if(items == null || items.length == 0) {				return false;			}			return true;		}				private var _opened:Boolean = false;		public function set opened (v:Boolean) :void { _opened = v; }		public function get opened () :Boolean { return _opened; }				public function addPopupItem (_label:String, shortcut:String="", data:Object=null) :WEPopupItem {						if(items == null) {				items = [];			}						items.push(new WEPopupItem());			var it:WEPopupItem = items[items.length-1];			it.label = _label;			it.shortcut = shortcut;			if(data != null) {				if(data.iconL != null) it.iconL = data.iconL;				if(data.iconR != null) it.iconR = data.iconR;				if(data.stateButton != null) it.stateButton = data.stateButton;				if(data.selected != null) it.selected = data.selected;				if(data.disabled != null) it.disabled = data.disabled;				it.data = data;			}						return items[items.length-1];		}				public function getItemByLabel (lb:String) :WEPopupItem {			var id:int=getItemIdByLabel(lb);			if(id>=0) {				return items[id];			}			return null;		}				public function getItemIdByLabel (lb:String) :int {			if(items == null) return -1;			var L:int = items.length;			var it:WEPopupItem;			for(var i:int=0; i<L; i++) {				if(items[i].label == lb) {					return i;				}			}			return -1;		}				public function toString ():String {			return label;		}			}}