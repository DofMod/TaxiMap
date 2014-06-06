package ui
{
	import d2actions.LeaveDialogRequest;
	import d2api.MapApi;
	import d2api.PlayedCharacterApi;
	import d2api.SystemApi;
	import d2api.UiApi;
	import d2api.UtilApi;
	import d2components.ButtonContainer;
	import d2components.Label;
	import d2components.MapViewer;
	import d2data.Hint;
	import d2data.HintCategory;
	import d2data.SubArea;
	import d2data.TeleportDestinationWrapper;
	import d2data.WorldMap;
	import d2data.WorldPointWrapper;
	import d2enums.ComponentHookList;
	import d2hooks.ZaapList;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	/**
	 * ...
	 * @author Relena
	 */
	public class TaxiMapUI
	{
		//::///////////////////////////////////////////////////////////
		//::// Variables
		//::///////////////////////////////////////////////////////////
		
		// Constants
		private static const LAYER_CHARACTER_POS:String = "layer_pos";
		private static const LAYER_ZAAP:String = "layer_zaap";
		private static const LAYER_PRISM:String = "layer_prism";
		
		private static const CHARACTER_POSITION_ID:String = "characterPosition";
		
		// APIs
		public var sysApi:SystemApi;
		public var uiApi:UiApi;
		public var playerApi:PlayedCharacterApi;
		public var mapApi:MapApi;
		public var utilApi:UtilApi;
		
		// Components
		public var mv_teleportMap:MapViewer;
		public var btn_close:ButtonContainer;
		public var btn_valid:ButtonContainer;
		public var lbl_kamas:Label;
		public var lbl_destinationName:Label;
		public var lbl_destinationCost:Label;
		
		// Globals
		private const _mapIconScale:int = 2;
		private var _prismsToAdd:Array = [];
		private var _zaapList:Vector.<TeleportDestinationWrapper> = new Vector.<TeleportDestinationWrapper>();
		private var _selectedZaap:Object = null;
		private var _characterPositionIcon:Object = null;
		private var _iconAssetPath:String = null;
		
		//::///////////////////////////////////////////////////////////
		//::// Public methods
		//::///////////////////////////////////////////////////////////
		
		/**
		 * UI entry point.
		 *
		 * @param	params	[destinations, teleporterType, currentMap:WorldPointWrapper]
		 */
		public function main(params:Array):void
		{
			_iconAssetPath = sysApi.getConfigEntry("config.gfx.path") + "icons/assets.swf|";
			
			uiApi.addComponentHook(mv_teleportMap, "onMapElementRollOver");
			uiApi.addComponentHook(mv_teleportMap, "onMapElementRollOut");
			uiApi.addComponentHook(mv_teleportMap, "onMapElementRightClick");
			
			uiApi.addComponentHook(btn_close, ComponentHookList.ON_RELEASE);
			uiApi.addComponentHook(btn_valid, ComponentHookList.ON_RELEASE);
			
			sysApi.addHook(ZaapList, onZaapList);
			
			uiApi.addShortcutHook(ShortcutEnum.CLOSE_UI, onShortcut);
			uiApi.addShortcutHook(ShortcutEnum.VALID_UI, onShortcut);
			
			lbl_kamas.text = utilApi.kamasToString(playerApi.characteristics().kamas, "");
			lbl_destinationName.text = "-";
			lbl_destinationCost.text = "0";
			
			updateMap(params[2]);
			
			onZaapList(params[0]);
		}
		
		//::///////////////////////////////////////////////////////////
		//::// Private methods
		//::///////////////////////////////////////////////////////////
		
		public function onRelease(target:Object):void
		{
			switch (target)
			{
				case btn_close: 
					sysApi.sendAction(new LeaveDialogRequest());
					
					break;
				case btn_valid:
					validateZaapChoice();
					
					break;
			}
		}
		
		public function onMapElementRollOver(param1:Object, param2:Object):void
		{
			if (!param2.legend)
			{
				return;
			}
			
			this.uiApi.showTooltip(uiApi.textTooltipInfo(param2.legend), param1, false, "standard", 7, 1, 3, null, null, null, "TextInfo");
		}
		
		public function onMapElementRollOut(param1:Object, param2:Object):void
		{
			this.uiApi.hideTooltip();
		}
		
		public function onMapElementRightClick(param1:Object, selectedZaap:Object):void
		{
			if (selectedZaap.x == _characterPositionIcon.x || selectedZaap.y == _characterPositionIcon.y)
			{
				return;
			}
			
			_selectedZaap = selectedZaap;
			
			var coords:String = _selectedZaap.x + "," + _selectedZaap.y;
			
			for each(var destination:TeleportDestinationWrapper in _zaapList)
			{
				if (destination.coord == coords)
				{
					lbl_destinationName.text = destination.name;
					lbl_destinationCost.text = destination.cost.toString();
					
					break;
				}
			}
		}
		
		/**
		 *
		 * @param	shortcutType
		 * @return	is shortcut intercapted.
		 */
		public function onShortcut(shortcutType:String):Boolean
		{
			switch (shortcutType)
			{
				case ShortcutEnum.VALID_UI: 
					validateZaapChoice();
					
					return true;
				case ShortcutEnum.CLOSE_UI: 
					sysApi.sendAction(new d2actions.LeaveDialogRequest());
					
					return true;
			}
			
			return false;
		}
		
		//::///////////////////////////////////////////////////////////
		//::// Private methods
		//::///////////////////////////////////////////////////////////
		
		private function updateMap(currentMap:WorldPointWrapper):void
		{
			var worldMap:WorldMap = null;
			var subarea:SubArea = playerApi.currentSubArea();
			if (subarea)
			{
				worldMap = subarea.worldmap;
			}
			if (!worldMap)
			{
				return;
			}
			
			mv_teleportMap.origineX = worldMap.origineX;
			mv_teleportMap.origineY = worldMap.origineY;
			mv_teleportMap.mapWidth = worldMap.mapWidth;
			mv_teleportMap.mapHeight = worldMap.mapHeight;
			mv_teleportMap.minScale = worldMap.minScale;
			mv_teleportMap.maxScale = worldMap.maxScale;
			mv_teleportMap.startScale = worldMap.startScale;
			mv_teleportMap.autoSizeIcon = true;
			
			mv_teleportMap.removeAllMap();
			
			loadMaps(worldMap);
			
			mv_teleportMap.finalize();
			mv_teleportMap.addLayer(LAYER_ZAAP);
			mv_teleportMap.addLayer(LAYER_PRISM);
			mv_teleportMap.addLayer(LAYER_CHARACTER_POS);
			
			_characterPositionIcon = mv_teleportMap.addIcon(LAYER_CHARACTER_POS, CHARACTER_POSITION_ID, _iconAssetPath + "myPosition2", currentMap.outdoorX, currentMap.outdoorY, 1, currentMap.outdoorX + "," + currentMap.outdoorY + " (" + uiApi.getText("ui.cartography.yourposition") + ")", true, 0xFF0000, false);
			if (_characterPositionIcon)
			{
				if (mv_teleportMap.autoSizeIcon)
				{
					_characterPositionIcon.texture.scaleY = 1;
					_characterPositionIcon.texture.scaleX = 1;
					mv_teleportMap.getMapElement(CHARACTER_POSITION_ID).canBeAutoSize = false;
				}
				
				_characterPositionIcon.texture.width = (worldMap ? worldMap.mapWidth : 69);
				_characterPositionIcon.texture.height = (worldMap ? worldMap.mapHeight : 50);
			}
			
			var hintsList:Object = mapApi.getHintIds();
			for each (var hint:Object in hintsList)
			{
				// Category
				// 9 : Zaap
				// 8 : 
				// 7 : Houses
				// 6 : Donjons
				// 5 : Prisms
				// 4 : Diver (place marchande, banque, enclos, taverne...)
				// 3 : Ateliers
				// 2 : HDV
				// 1 : Temples
				
				// Gfx
				// 130, Passage secret des Roublards
				// 150, Sous-marin Steamer
				// 401, Banque
				// 402, Canon
				// 403, Église
				// 404, Chanil
				// 405, Temple des guildes
				// 406, Kanojedo
				// 407, Milice
				// 408, Bar Akouda
				// 408, Taverne du Ripate
				// 410, Zaap
				// 411, Arène
				// 412, Transporteur frigostien
				// 413, Bateau vers le temple des alliances
				// 414, Dojo
				// 415, Place Marchande
				// 416, Tour des ordres
				// 417, Tour des archives
				// 418, Hôtel des métiers
				// 419, Enclos public
				// 423, Attitude "Être frigorifié
				// 425, Épicerie
				// 426, Médecin de Frigost
				// 427, Fabricant de skis
				// 428, Cratère Pillar
				// 429, Kolizéum
				// 433, Quai des gelées
				// 434, Maison Krosmaster
				// 435, Sanctuaire de l'Almanax
				// 437, Temple des alliances
				// 438, Foreuse
				// 439, Canon pour l'île de Moon
				// 900, Passage vers le berceau d'Alma
				if (hint.worldMapId == worldMap.id && hint.category == 9 && hint.gfx == 410)
				{
					if (hint.x == _characterPositionIcon.x && hint.y == _characterPositionIcon.y)
					{
						mv_teleportMap.addIcon(LAYER_ZAAP, "zaap_" + hint.id, _iconAssetPath + "icon_" + hint.gfx, hint.x, hint.y, _mapIconScale);
					}
					else
					{
						mv_teleportMap.addIcon(LAYER_ZAAP, "zaap_" + hint.id, _iconAssetPath + "icon_" + hint.gfx, hint.x, hint.y, _mapIconScale, hint.x + "," + hint.y + " (" + hint.name + ")", true);
					}
				}
			}
			
			//if (_prismsToAdd.length > 0)
			//{
			//while (_prismsToAdd.length > 0)
			//{
			//
			//var prism:* = _prismsToAdd.shift();
			//mv_teleportMap.addIcon("layer_5", prism.prismId, prism.icon, prism.prismX, prism.prismY, _mapIconScale);
			//}
			//}
			
			mv_teleportMap.moveTo(currentMap.outdoorX, currentMap.outdoorY);
			mv_teleportMap.updateMapElements();
		}
		
		private function loadMaps(worldMap:WorldMap):void
		{
			var pathBase:String = uiApi.me().getConstant("maps_uri") + worldMap.id.toString() + "/";
			for each (var zoom:*in worldMap.zoom)
			{
				mv_teleportMap.addMap(parseFloat(zoom), pathBase + zoom + "/", worldMap.totalWidth, worldMap.totalHeight, 250, 250);
			}
		}
		
		/**
		 * ZaapList hook callback.
		 *
		 * @param	destinations	Destination list. (d2data.TeleportDestinationWrapper)
		 */
		protected function onZaapList(destinations:Object):void
		{
			if (destinations.length == 0)
			{
			}
			else
			{
				_zaapList = new Vector.<TeleportDestinationWrapper>();
				
				for each (var destination:TeleportDestinationWrapper in destinations)
				{
					//if (destination.mapId == this.playerApi.currentMap().mapId)
					//{
						//this._teleportType = destination.destinationType;
					//}
					//else if (destination.destinationType == d2enums.TeleporterTypeEnum.TELEPORTER_ZAAP)
					//{
						//this._tab1List.push(destination);
					//}
					//else if (destination.destinationType == d2enums.TeleporterTypeEnum.TELEPORTER_PRISM)
					//{
						//this._tab2List.push(destination);
					//}
					
					_zaapList.push(destination);
				}
			}
		}
		
		private function validateZaapChoice():void
		{
			if (!_selectedZaap)
			{
				return;
			}
			
			var coords:String = _selectedZaap.x + "," + _selectedZaap.y;
			
			for each(var destination:TeleportDestinationWrapper in _zaapList)
			{
				if (destination.coord == coords)
				{
					sysApi.log(16, "go go go: " + coords);
					//sysApi.sendAction(new d2actions.TeleportRequest(destination.destinationType, destination.mapId, destination.cost));
					
					break;
				}
			}
		}
	}
}
