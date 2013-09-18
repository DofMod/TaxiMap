package
{
	import d2api.SystemApi;
	import d2api.UiApi;
	import d2data.PrismSubAreaWrapper;
	import d2data.WorldPointWrapper;
	import d2enums.TeleporterTypeEnum;
	import d2hooks.LeaveDialog;
	import d2hooks.MapComplementaryInformationsData;
	import d2hooks.PrismWorldInformation;
	import d2hooks.TeleportDestinationList;
	import flash.display.Sprite;
	import ui.TaxiMapUI;
	
	/**
	 * Entry point class.
	 *
	 * @author Relena
	 */
	public class TaxiMap extends Sprite
	{
		//::///////////////////////////////////////////////////////////
		//::// Variables
		//::///////////////////////////////////////////////////////////
		
		// UIs
		private static const includeUIs:Array = [TaxiMapUI];
		
		// APIs
		public var sysApi:SystemApi;
		public var uiApi:UiApi;
		
		// Constants
		private static const taxiMapUIName:String = "taxiMap";
		private static const taxiMapUIInstanceName:String = "taxiMap";
		
		// Globals
		private var _currentMap:WorldPointWrapper = null;
		
		//private var _prisms:Vector.<PrismSubAreaWrapper> = new Vector.<PrismSubAreaWrapper>();
		
		//::///////////////////////////////////////////////////////////
		//::// Public methods
		//::///////////////////////////////////////////////////////////
		
		/**
		 * Module entry point.
		 */
		public function main():void
		{
			sysApi.addHook(TeleportDestinationList, onTeleportDestinationList);
			sysApi.addHook(MapComplementaryInformationsData, onMapComplementaryInformationsData);
			sysApi.addHook(LeaveDialog, onLeaveDialog);
		}
		
		//::///////////////////////////////////////////////////////////
		//::// Events
		//::///////////////////////////////////////////////////////////
		
		/**
		 * MapComplementaryInformationsData hook callback.
		 *
		 * @param	currentMap	Current map information.
		 * @param	currentSubAreaId	Current subarea identifier.
		 * @param	displayMapCoordinate	Display map coordinate ?
		 */
		private function onMapComplementaryInformationsData(currentMap:WorldPointWrapper, currentSubAreaId:int, displayMapCoordinate:Boolean):void
		{
			_currentMap = currentMap;
		}
		
		// hook not available
		private function onPrismsListInformation(param1:Object):void
		{
			//_prisms = ...
		}
		
		/**
		 * TeleportDestinationList hook callback.
		 *
		 * @param	destinations	Destination list. (d2data.TeleportDestinationWrapper)
		 * @param	teleporterType	Teleporter type. (See d2enum.TeleportTypeEnum)
		 */
		private function onTeleportDestinationList(destinations:Object, teleporterType:uint):void
		{
			if (teleporterType == TeleporterTypeEnum.TELEPORTER_ZAAP)
			{
				uiApi.loadUi(taxiMapUIName, taxiMapUIInstanceName, [destinations, teleporterType, _currentMap]);
			}
			else if (teleporterType == TeleporterTypeEnum.TELEPORTER_SUBWAY)
			{
				// TODO.
			}
		}
		
		public function onLeaveDialog():void
		{
			if (uiApi.getUi(taxiMapUIInstanceName))
			{
				uiApi.unloadUi(taxiMapUIInstanceName);
			}
		}
	
		//::///////////////////////////////////////////////////////////
		//::// Private methods
		//::///////////////////////////////////////////////////////////
	}
}
