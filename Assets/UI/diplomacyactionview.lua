-- Changes are marked by the code FF16~
-- Update 1.1 - Fixed base game bug preventing recent gossip entries from being highlighted.

-- ===========================================================================
-- Diplomacy Trade View Manager
-- ===========================================================================
include( "InstanceManager" );
include( "SupportFunctions" );
include( "Civ6Common" );
include( "LeaderSupport" );
include( "DiplomacyRibbonSupport" );
include( "DiplomacyStatementSupport" );
include( "TeamSupport" );
include( "GameCapabilities" );
include( "LeaderIcon" );
include( "PopupDialog" );
-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local LEADERTEXT_PADDING_X		:number		= 40;
local LEADERTEXT_PADDING_Y		:number		= 40;
local SELECTION_PADDING_Y		:number		= 20;

local OVERVIEW_MODE = 0;
local CONVERSATION_MODE = 1;
local CINEMA_MODE = 2;
local DEAL_MODE = 3;
local SIZE_BUILDING_ICON	:number = 32;
local SIZE_UNIT_ICON		:number = 32;
local INTEL_NO_SUB_PANEL			= -1;
local INTEL_ACCESS_LEVEL_PANEL		= 0;
local INTEL_RELATIONSHIP_PANEL		= 1;
local INTEL_GOSSIP_HISTORY_PANEL	= 2;
local INTEL_AGENDA_PANEL			= 3;
local COLOR_BLUE_GRAY				= 0xFF9c8772;
local COLOR_BUTTONTEXT_SELECTED			= 0xFF291F10;
local COLOR_BUTTONTEXT_SELECTED_SHADOW	= 0xAAD8B489;
local COLOR_BUTTONTEXT_NORMAL			= 0xFFC9DAE7;
local COLOR_BUTTONTEXT_NORMAL_SHADOW	= 0xA291F10;
local COLOR_BUTTONTEXT_DISABLED			= 0xFF90999F;
local DIPLOMACY_RIBBON_OFFSET			= 64;
local MAX_BEFORE_TRUNC_BUTTON_INST		= 280;

local TEAM_RIBBON_SIZE				:number = 53;
local TEAM_RIBBON_SMALL_SIZE		:number = 30;
local TEAM_RIBBON_PREFIX			:string = "ICON_TEAM_RIBBON_";

local VOICEOVER_SUPPORT: table = {"KUDOS", "WARNING", "DECLARE_WAR_FROM_HUMAN", "DECLARE_WAR_FROM_AI", "FIRST_MEET", "DEFEAT","ENRAGED"};

--This is the multiplier for the portion of the screen which the conversation control should cover.
local CONVO_X_MULTIPLIER	= .328;

-- ===========================================================================
--	VARIABLES
-- ===========================================================================
local ms_PlayerPanelIM		:table		= InstanceManager:new( "PlayerPanel",  "Root" );
local ms_DiplomacyRibbonIM	:table		= InstanceManager:new( "DiplomacyRibbonVert",  "Root" );
local ms_DiplomacyRibbonLeaderIM	:table		= InstanceManager:new( "DiplomacyRibbonLeader",  "Root" );
local ms_IconOnlyIM			:table		= InstanceManager:new( "IconOnly",  "Icon");
local ms_TextOnlyIM			:table		= InstanceManager:new( "TextOnly",  "Text", Controls.TextContainer );
local ms_IconAndTextIM		:table		= InstanceManager:new( "IconAndText",  "SelectButton", Controls.IconAndTextContainer );
local ms_LeftRightListIM	:table		= InstanceManager:new( "LeftRightList",  "List", Controls.LeftRightListContainer );
local ms_TopDownListIM		:table		= InstanceManager:new( "TopDownList",  "List", Controls.TopDownListContainer );

local ms_ActionListIM		:table		= InstanceManager:new( "ActionButton",  "Button" );
local ms_SubActionListIM	:table		= InstanceManager:new( "ActionButton",  "Button" );

local ms_IntelPanelIM				:table	= InstanceManager:new( "IntelPanel",  "Panel" );
local ms_IntelAccessLevelPanelIM	:table	= InstanceManager:new( "IntelAccessLevelPanel",  "Background" );
local ms_IntelRelationshipPanelIM	:table	= InstanceManager:new( "IntelRelationshipPanel",  "Background" );
local ms_IntelRelationshipReasonIM	:table	= InstanceManager:new( "IntelRelationshipReasonEntry",  "Background" );
local ms_RelationshipIconsIM		:table	= InstanceManager:new( "RelationshipIcon",  "Background" );

local ms_IntelGossipHistoryPanelEntryIM	:table	= InstanceManager:new( "IntelGossipHistoryPanelEntry",  "Background" );
local ms_IntelGossipHistoryPanelIM		:table	= InstanceManager:new( "IntelGossipHistoryPanel",  "Background" );

local ms_IntelAgendaPanelEntryIM	:table	= InstanceManager:new( "IntelAgendaPanelEntry",  "Background" );
local ms_IntelAgendaPanelIM			:table	= InstanceManager:new( "IntelAgendaPanel",  "Background" );

local ms_ConversationSelectionIM :table		= InstanceManager:new( "ConversationSelectionInstance",  "SelectionButton", Controls.ConversationSelectionStack );

local ms_uniqueIconIM :table	= InstanceManager:new("IconInfoInstance", "Top", Controls.FeaturesStack );
local ms_uniqueTextIM :table	= InstanceManager:new("TextInfoInstance", "Top", Controls.FeaturesStack );

local ms_ValueEditDealItemID = -1;		-- The ID of the deal item that is being value edited.
local ms_ValueEditDealItemControlTable = nil; -- The control table of the deal item that is being edited.

local OTHER_PLAYER = 0;
local LOCAL_PLAYER = 1;

local ms_PlayerPanel =		nil;
local ms_DiplomacyRibbon =	nil;

local ms_LocalPlayer =		nil;
local ms_LocalPlayerID =	-1;
local ms_LocalPlayerLeaderID = -1;

-- The 'other' player who may have contacted local player, which brought us to this view.  Can be nil.
local ms_OtherPlayer =		nil;
local ms_OtherPlayerID =	-1;

-- The selected player. This can be any player, including the local player
local ms_SelectedPlayer		= nil;
local ms_SelectedPlayerID	= -1;
local ms_SelectedPlayerLeaderTypeName = nil;

local ms_showingLeaderName = "";
local ms_bLeaderShowRequested = false;

-- A list of all the ribbon entries indexed by the leader ID
local ms_LeaderIDToRibbonEntry = {};

local ms_InitiatedByPlayerID = -1;

local ms_bIsViewInitialized = false;

local ms_ActiveSessionID = nil;

local ms_currentViewMode = -1;

local ms_bShowingDeal = false;

local m_isInHotload = false;

local m_bCloseSessionOnFadeComplete = false;

local m_bottomPanelHeight = 0;
local PADDING_FOR_SCROLLPANEL = 220;
local m_GossipThisTurnCount = 0;
local m_firstOpened = true;
local m_LeaderCoordinates		:table = {};
local m_lastLeaderPlayedMusicFor = -1;

local ms_LastDealResponseAnimation = nil;

-- VOICEOVER SUPPORT
local m_voiceoverText		:string = "";
local m_cinemaMode			:boolean = false;
local m_currentLeaderAnim	:string = "";
local m_currentSceneEffect	:string = "";

local ms_OtherID;

local m_PopupDialog :table = PopupDialog:new("ConfirmDenounce");

--CQUI Members
local CQUI_trimGossip = true;

function CQUI_OnSettingsUpdate()
  CQUI_trimGossip = GameConfiguration.GetValue("CQUI_TrimGossip");
end

LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnSettingsUpdate );
LuaEvents.CQUI_SettingsInitialized.Add( CQUI_OnSettingsUpdate );

-- ===========================================================================
function GetOtherPlayer(player : table)
  if (player ~= nil and player:GetID() == ms_OtherPlayer:GetID()) then
    return ms_LocalPlayer;
  end

  return ms_OtherPlayer;
end

-- ===========================================================================
function GetStatementMood( fromPlayer : number, inputMood : number )

  local pPlayer = Players[fromPlayer];
  local otherPlayerID = GetOtherPlayer(pPlayer):GetID();

  local eFromPlayerMood = inputMood;
  if (inputMood == DiplomacyMoodTypes.UNDEFINED) then
    -- If the mood was not defined in the statement, get the current mood.  This is most often the case because when the statement has been sent, the
    -- diplomacy action that it is in reaction to has usually not taken effect, so the mood is not correct at that time.
    return DiplomacySupport_GetPlayerMood(pPlayer, otherPlayerID);
  else
    return inputMood;
  end
end

local DiplomaticStateIndexToVisState = {};

DiplomaticStateIndexToVisState[DiplomaticStates.ALLIED] = 0;
DiplomaticStateIndexToVisState[DiplomaticStates.DECLARED_FRIEND] = 1;
DiplomaticStateIndexToVisState[DiplomaticStates.FRIENDLY] = 2;
DiplomaticStateIndexToVisState[DiplomaticStates.NEUTRAL] = 3;
DiplomaticStateIndexToVisState[DiplomaticStates.UNFRIENDLY] = 4;
DiplomaticStateIndexToVisState[DiplomaticStates.DENOUNCED] = 5;
DiplomaticStateIndexToVisState[DiplomaticStates.WAR] = 6;

-- ===========================================================================
-- Take the diplomatic state index and convert it to a vis state index for our icons
-- Yes, *currently* the index state is the same, but it is NOT good practice
-- to assume starting position or order of a database item, ever.
function GetVisStateFromDiplomaticState(iState)

  local eStateHash = GameInfo.DiplomaticStates[iState].Hash;
  local iVisState = DiplomaticStateIndexToVisState[eStateHash];

  if (iVisState ~= nil) then
    return iVisState;
  end

  return 0;
end

-- ===========================================================================
function UpdateSelectedPlayer(allowDeadPlayer)

  if (allowDeadPlayer == nil) then
    allowDeadPlayer = false;
  end

  -- Have we met them and are they in the ribbon (alive) or allowing dead players (for defeat messages)
  if (ms_LocalPlayer:GetDiplomacy():HasMet(ms_SelectedPlayerID) and (allowDeadPlayer == true or ms_LeaderIDToRibbonEntry[ms_SelectedPlayerID] ~= nil)) then
    ms_SelectedPlayer = Players[ms_SelectedPlayerID];
  else
    ms_SelectedPlayer = ms_LocalPlayer;
    ms_SelectedPlayerID = ms_LocalPlayerID;
  end

  if (ms_SelectedPlayer ~= nil) then
    local playerConfig = PlayerConfigurations[ms_SelectedPlayer:GetID()];
    if (playerConfig ~= nil) then
      ms_SelectedPlayerLeaderTypeName = playerConfig:GetLeaderTypeName();
            ms_OtherCivilizationID = playerConfig:GetCivilizationTypeID();
            ms_OtherLeaderID = playerConfig:GetLeaderTypeID();
            ms_OtherID = ms_SelectedPlayer:GetID();
    end
  end

end

-- ===========================================================================
function CreateHorizontalGroup(rootStack : table, title : string)
  local iconList = ms_LeftRightListIM:GetInstance(rootStack);
  if (title == nil or title == "") then
    iconList.Title:SetHide(true);		-- No title
  else
    iconList.TitleText:LocalizeAndSetText(title);
  end

  iconList.List:ReprocessAnchoring();

  return iconList;
end

-- ===========================================================================
function CreateVerticalGroup(rootStack : table, title : string)
  local iconList = ms_TopDownListIM:GetInstance(rootStack);
  if (title == nil or title == "") then
    iconList.Title:SetHide(true);		-- No title
  else
    iconList.TitleText:LocalizeAndSetText(title);
  end

  iconList.List:ReprocessAnchoring();

  return iconList;
end


-- ===========================================================================
function CreatePlayerPanel(rootControl : table)

  local playerPanel = ms_PlayerPanelIM:GetInstance(rootControl);

  playerPanel.ContentStack:CalculateSize();
  playerPanel.SubOptionsStack:CalculateSize();
  playerPanel.RootStack:ReprocessAnchoring();
  playerPanel.RootStack:CalculateSize();
  playerPanel.RootStack:ReprocessAnchoring();

  rootControl:ReprocessAnchoring();

  return playerPanel;
end

-- ===========================================================================
function CreateDiplomacyRibbon(rootControl : table)

  local diplomacyRibbon = ms_DiplomacyRibbonIM:GetInstance(rootControl);

  return diplomacyRibbon;
end

-- ===========================================================================
function CreateValueEditOverlay()

  Controls.ValueEditLeft:RegisterCallback( Mouse.eLClick, function() OnValueEditDelta(-1); end );
    Controls.ValueEditLeft:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
  Controls.ValueEditRight:RegisterCallback( Mouse.eLClick, function() OnValueEditDelta(1); end );
    Controls.ValueEditRight:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

  Controls.ValueEdit:RegisterCommitCallback( OnValueEditCommit );

end

-- ===========================================================================
function CreatePanels()

  CreateValueEditOverlay();

  -- Create the Player Panel
  ms_PlayerPanel = CreatePlayerPanel(Controls.PlayerContainer);
  -- Create the Diplomacy Ribbon
  ms_DiplomacyRibbon = CreateDiplomacyRibbon(Controls.DiplomacyRibbonContainer);

end

-- ===========================================================================
-- Show or hide the "amount text" sub-control of the supplied control instance
function SetHideAmountText(controlTable : table, bHide : boolean)

  if (controlTable ~= nil) then
    if (controlTable.AmountText ~= nil) then
      controlTable.AmountText:SetHide(bHide);
    end
  end
end

-- ===========================================================================
-- Detach the value edit overlay from anything it is attached to.
function ClearValueEdit()

  SetHideAmountText(ms_ValueEditDealItemControlTable, false);

  ms_ValueEditDealItemControlTable = nil
  ms_ValueEditDealItemID = -1;

  Controls.ValueEditOverlay:SetHide(true);

end

-- ===========================================================================
-- Clamp the input value to the max the value can have for the type of item
-- Do we want to have this as a function on the item?
function ClampValueAmount(playerID : number, eDealItemType : number, eValueType : number, iAmount : number)

  return iAmount;
end

-- ===========================================================================
-- Change the value edit by a delta
function OnValueEditDelta(delta : number)

end

-- ===========================================================================
-- Commit the value in the edit control to the deal item
function OnValueEditCommit()

end

-- ===========================================================================
-- Detach the value edit if it is attached to the control
function DetachValueEdit(itemID: number)

  if (itemID == ms_ValueEditDealItemID) then
    ClearValueEdit();
  end

end

-- ===========================================================================
-- Reattach the value edit overlay to the control set it is editing.
function ReAttachValueEdit()

  if (ms_ValueEditDealItemControlTable ~= nil) then

    local rootControl = ms_ValueEditDealItemControlTable.SelectButton;

    -- Position over the deal item.  We do this, rather than attaching to the item as a child, because we want to always be on top over everything.
    local x, y = rootControl:GetScreenOffset();
    local w, h = rootControl:GetSizeVal();
    Controls.ValueEditOverlay:SetOffsetVal(x + (w/2), y + h);
    Controls.ValueEditOverlay:SetHide(false);

    SetHideAmountText(ms_ValueEditDealItemControlTable, true);

    rootControl:ReprocessAnchoring();
  end

end


-- ===========================================================================
-- Make sure the active session is still there.
function ValidateActiveSession()

  if (ms_ActiveSessionID ~= nil) then
    if (not DiplomacyManager.IsSessionIDOpen(ms_ActiveSessionID)) then
      ms_ActiveSessionID = nil;
      return false;
    end
  end

  return true;
end

-- ===========================================================================
-- Exit the conversation mode.
function ExitConversationMode()

  if (ms_currentViewMode == CONVERSATION_MODE) then
    ValidateActiveSession();
    if (ms_ActiveSessionID ~= nil) then
      -- Close the session, this will handle exiting back to OVERVIEW_MODE or exiting, if the other leader contacted us.
      if (HasNextQueuedSession(ms_ActiveSessionID)) then
        -- There is another session right after this one, so we want to delay sending the CloseSession until the screen goes to black.
        m_bCloseSessionOnFadeComplete = true;
        StartFadeOut();
      else
        -- Close the session now.
        DiplomacyManager.CloseSession( ms_ActiveSessionID );
      end
    else
      -- No session for some reason, just go directly back.
      SelectPlayer(ms_OtherPlayerID, OVERVIEW_MODE);
    end
    ResetPlayerPanel();
  end
end

-- ===========================================================================
function StartFadeOut()
  Controls.BlackFade:SetHide(false);
  Controls.BlackFadeAnim:SetToBeginning();
  Controls.BlackFadeAnim:Play();
  Controls.FadeTimerAnim:SetToBeginning();
  Controls.FadeTimerAnim:Play();
end

-- ===========================================================================
function StartFadeIn()
  Controls.BlackFade:SetHide(false);

  -- Only do the BlackFadeAnim
  Controls.BlackFadeAnim:SetToBeginning();	-- This forces a clear of the reverse flag.
  Controls.BlackFadeAnim:SetToEnd();
  Controls.BlackFadeAnim:Reverse();
end

-- ===========================================================================
function IsWarChoice(key)
  local isWar :boolean = key == "CHOICE_DECLARE_SURPRISE_WAR"
    or key == "CHOICE_DECLARE_FORMAL_WAR"
    or key == "CHOICE_DECLARE_HOLY_WAR"
    or key == "CHOICE_DECLARE_LIBERATION_WAR"
    or key == "CHOICE_DECLARE_RECONQUEST_WAR"
    or key == "CHOICE_DECLARE_PROTECTORATE_WAR"
    or key == "CHOICE_DECLARE_COLONIAL_WAR"
    or key == "CHOICE_DECLARE_TERRITORIAL_WAR";
  return isWar;
end

function GetWarType(key)
    if (key == "CHOICE_DECLARE_FORMAL_WAR") then return WarTypes.FORMAL_WAR; end;
    if (key == "CHOICE_DECLARE_HOLY_WAR") then return WarTypes.HOLY_WAR; end;
    if (key == "CHOICE_DECLARE_LIBERATION_WAR") then return WarTypes.LIBERATION_WAR; end;
    if (key == "CHOICE_DECLARE_RECONQUEST_WAR") then return WarTypes.RECONQUEST_WAR; end;
    if (key == "CHOICE_DECLARE_PROTECTORATE_WAR") then return WarTypes.PROTECTORATE_WAR; end;
    if (key == "CHOICE_DECLARE_COLONIAL_WAR") then return WarTypes.COLONIAL_WAR; end;
    if (key == "CHOICE_DECLARE_TERRITORIAL_WAR") then return WarTypes.TERRITORIAL_WAR; end;

    return WarTypes.SURPRISE_WAR;
end

function GetGoldCost(key)

    local szActionString = "";

    if (key == "CHOICE_DIPLOMATIC_DELEGATION") then szActionString = "DIPLOACTION_DIPLOMATIC_DELEGATION"; end;
    if (key == "CHOICE_RESIDENT_EMBASSY") then szActionString = "DIPLOACTION_RESIDENT_EMBASSY"; end;
    if (key == "CHOICE_OPEN_BORDERS") then szActionString = "DIPLOACTION_OPEN_BORDERS"; end;

    if (szActionString == "") then return 0; end;

    return ms_LocalPlayer:GetDiplomacy():GetDiplomaticActionCost(szActionString);
end

-- ===========================================================================
function IsPeaceChoice(key)
  local isPeace :boolean = (key == "CHOICE_MAKE_PEACE");
  return isPeace;
end

-- ===========================================================================
-- Handle a statement selection from the OVERVIEW_MODE.  We are not
-- in a session with the other player yet, this will start one.
function OnSelectInitialDiplomacyStatement(key)

  if (ms_LocalPlayerID ~= ms_SelectedPlayerID and ms_SelectedPlayerID >= 0 and not GameConfiguration.IsPaused()) then

    if (key == "CHOICE_DECLARE_SURPRISE_WAR") then
      DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "DECLARE_SURPRISE_WAR");

    elseif (key == "CHOICE_DECLARE_FORMAL_WAR") then
      DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "DECLARE_FORMAL_WAR");

    elseif (key == "CHOICE_DECLARE_HOLY_WAR") then
      DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "DECLARE_HOLY_WAR");

    elseif (key == "CHOICE_DECLARE_LIBERATION_WAR") then
      DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "DECLARE_LIBERATION_WAR");

    elseif (key == "CHOICE_DECLARE_RECONQUEST_WAR") then
      DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "DECLARE_RECONQUEST_WAR");

    elseif (key == "CHOICE_DECLARE_PROTECTORATE_WAR") then
      DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "DECLARE_PROTECTORATE_WAR");

    elseif (key == "CHOICE_DECLARE_COLONIAL_WAR") then
      DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "DECLARE_COLONIAL_WAR");

    elseif (key == "CHOICE_DECLARE_TERRITORIAL_WAR") then
      DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "DECLARE_TERRITORIAL_WAR");

    elseif (key == "CHOICE_MAKE_PEACE") then
        -- DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "MAKE_PEACE");
        -- Clear the outgoing deal, if we have nothing pending, so the user starts out with an empty deal.
        if (not DealManager.HasPendingDeal(ms_LocalPlayerID, ms_SelectedPlayerID)) then
          DealManager.ClearWorkingDeal(DealDirection.OUTGOING, ms_LocalPlayerID, ms_SelectedPlayerID);
          local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING, ms_LocalPlayer:GetID(), ms_SelectedPlayerID);
          if (pDeal ~= nil) then
            pDealItem = pDeal:AddItemOfType(DealItemTypes.AGREEMENTS, ms_LocalPlayer:GetID());
            if (pDealItem ~= nil) then
              pDealItem:SetSubType(DealAgreementTypes.MAKE_PEACE);
              pDealItem:SetLocked(true);
            end
            -- Validate the deal, this will make sure peace is on both sides of the deal.
            pDeal:Validate();
          end
        end
        DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "MAKE_DEAL");
    elseif (key == "CHOICE_MAKE_DEAL") then
        -- Clear the outgoing deal, if we have nothing pending, so the user starts out with an empty deal.
        if (not DealManager.HasPendingDeal(ms_LocalPlayerID, ms_SelectedPlayerID)) then
          DealManager.ClearWorkingDeal(DealDirection.OUTGOING, ms_LocalPlayerID, ms_SelectedPlayerID);
        end
        DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "MAKE_DEAL");
    elseif (key == "CHOICE_VIEW_DEAL") then
        DealManager.ViewPendingDeal(ms_LocalPlayerID, ms_SelectedPlayerID);
    elseif (key == "CHOICE_MAKE_DEMAND") then
        -- Clear the outgoing deal, if we have nothing pending, so the user starts out with an empty deal.
        if (not DealManager.HasPendingDeal(ms_LocalPlayerID, ms_SelectedPlayerID)) then
          DealManager.ClearWorkingDeal(DealDirection.OUTGOING, ms_LocalPlayerID, ms_SelectedPlayerID);
        end
        DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "MAKE_DEMAND");
    elseif (key == "CHOICE_VIEW_DEMAND") then
        DealManager.ViewPendingDeal(ms_LocalPlayerID, ms_SelectedPlayerID);
    elseif (key == "CHOICE_DENOUNCE") then
        DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "DENOUNCE");
    elseif (key == "CHOICE_DIPLOMATIC_DELEGATION") then
        DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "DIPLOMATIC_DELEGATION");
    elseif (key == "CHOICE_DECLARE_FRIENDSHIP") then
        DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "DECLARE_FRIEND");
    elseif (key == "CHOICE_RESIDENT_EMBASSY") then
        DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "RESIDENT_EMBASSY");
    elseif (key == "CHOICE_OPEN_BORDERS") then
        DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "OPEN_BORDERS");
    elseif (key == "CHOICE_DEMAND_PROMISE_DONT_SPY") then
        DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "WARNING_STOP_SPYING_ON_ME");
    elseif (key == "CHOICE_DEMAND_PROMISE_DONT_SETTLE_TOO_NEAR") then
        DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "WARNING_DONT_SETTLE_NEAR_ME");
    elseif (key == "CHOICE_DEMAND_PROMISE_DONT_CONVERT_CITY") then
        DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "WARNING_STOP_CONVERTING_MY_CITIES");
    elseif (key == "CHOICE_DEMAND_PROMISE_DONT_DIG_ARTIFACTS") then
        DiplomacyManager.RequestSession(ms_LocalPlayerID, ms_SelectedPlayerID, "WARNING_STOP_DIGGING_UP_ARTIFACTS");
    end
  end

end

-- ===========================================================================
-- Handle a statment selection when in CONVERSATION_MODE.  We will already be
-- in a session with the other player.
function OnSelectConversationDiplomacyStatement(key)

  if (key == "CHOICE_EXIT") then
    ExitConversationMode();
  else
    if (key == "CHOICE_DECLARE_SURPRISE_WAR") then
      DiplomacyManager.AddStatement(ms_ActiveSessionID, Game.GetLocalPlayer(), "DECLARE_SURPRISE_WAR");

    elseif (key == "CHOICE_DECLARE_FORMAL_WAR") then
      DiplomacyManager.AddStatement(ms_ActiveSessionID, Game.GetLocalPlayer(), "DECLARE_FORMAL_WAR");

    elseif (key == "CHOICE_DECLARE_HOLY_WAR") then
      DiplomacyManager.AddStatement(ms_ActiveSessionID, Game.GetLocalPlayer(), "DECLARE_HOLY_WAR");

    elseif (key == "CHOICE_DECLARE_LIBERATION_WAR") then
      DiplomacyManager.AddStatement(ms_ActiveSessionID, Game.GetLocalPlayer(), "DECLARE_LIBERATION_WAR");

    elseif (key == "CHOICE_DECLARE_RECONQUEST_WAR") then
      DiplomacyManager.AddStatement(ms_ActiveSessionID, Game.GetLocalPlayer(), "DECLARE_RECONQUEST_WAR");

    elseif (key == "CHOICE_DECLARE_PROTECTORATE_WAR") then
      DiplomacyManager.AddStatement(ms_ActiveSessionID, Game.GetLocalPlayer(), "DECLARE_PROTECTORATE_WAR");

    elseif (key == "CHOICE_DECLARE_COLONIAL_WAR") then
      DiplomacyManager.AddStatement(ms_ActiveSessionID, Game.GetLocalPlayer(), "DECLARE_COLONIAL_WAR");

    elseif (key == "CHOICE_DECLARE_TERRITORIAL_WAR") then
      DiplomacyManager.AddStatement(ms_ActiveSessionID, Game.GetLocalPlayer(), "DECLARE_TERRITORIAL_WAR");

    elseif (key == "CHOICE_MAKE_PEACE") then
        DiplomacyManager.AddStatement(ms_ActiveSessionID, Game.GetLocalPlayer(), "MAKE_PEACE");
    elseif (key == "CHOICE_MAKE_DEAL") then
        DiplomacyManager.AddStatement(ms_ActiveSessionID, Game.GetLocalPlayer(), "MAKE_DEAL");
    elseif (key == "CHOICE_MAKE_DEMAND") then
        DiplomacyManager.AddStatement(ms_ActiveSessionID, Game.GetLocalPlayer(), "MAKE_DEMAND");
    else
      if (key == "CHOICE_POSITIVE") then
        DiplomacyManager.AddResponse(ms_ActiveSessionID, Game.GetLocalPlayer(), "POSITIVE");
      else
        if (key == "CHOICE_NEGATIVE") then
          DiplomacyManager.AddResponse(ms_ActiveSessionID, Game.GetLocalPlayer(), "NEGATIVE");
        else
          if (key == "CHOICE_IGNORE") then
            DiplomacyManager.AddResponse(ms_ActiveSessionID, Game.GetLocalPlayer(), "RESPONSE_IGNORE");
          else
            -- Just pass the choice key through as a response string.
            DiplomacyManager.AddResponse(ms_ActiveSessionID, Game.GetLocalPlayer(), key);
          end
        end
      end
    end
  end
end

-- ===========================================================================
-- This applies the current statement to the CONVERSATION_MODE controls
function ApplyStatement(handler : table, statementTypeName : string, statementSubTypeName : string, toPlayer : number, kStatement : table)

  local eFromPlayerMood = GetStatementMood( kStatement.FromPlayer, kStatement.FromPlayerMood);
  local kParsedStatement = handler.ExtractStatement(handler, statementTypeName, statementSubTypeName, kStatement.FromPlayer, eFromPlayerMood, kStatement.Initiator);
  handler.RemoveInvalidSelections(kParsedStatement, ms_LocalPlayerID, ms_OtherPlayerID);

  local leaderstr :string = "";
  local reasonStr :string = "";

  if (kParsedStatement.StatementText ~= nil) then
    leaderstr = Locale.Lookup( DiplomacyManager.FindTextKey( kParsedStatement.StatementText, kStatement.FromPlayer, kStatement.FromMood, toPlayer));
    local reasonStrKey : string = DiplomacyManager.FindReasonTextKey( kParsedStatement.ReasonText, kStatement.FromPlayer, kStatement.AiReason, kStatement.AiModifier);
    if ( reasonStrKey ~= nil ) then
      reasonStr = Locale.Lookup( reasonStrKey );
    end
    Controls.LeaderResponseText:SetText( leaderstr );
    Controls.LeaderResponseText:ReprocessAnchoring();
    m_voiceoverText = leaderstr;
  end

  ms_ConversationSelectionIM:ResetInstances();

  if (kParsedStatement.Selections ~= nil) then
    for _, selection in ipairs(kParsedStatement.Selections) do
      local instance		:table	= ms_ConversationSelectionIM:GetInstance();
      instance.SelectionText:SetText( Locale.Lookup(selection.Text) );

      local texth			:number	= math.max( instance.SelectionText:GetSizeY() + SELECTION_PADDING_Y, 45 );
      instance.SelectionButton:SetSizeY( texth );
      instance.SelectionText:ReprocessAnchoring();
      if (selection.IsDisabled == nil or selection.IsDisabled == false) then
        instance.SelectionButton:SetDisabled( false );
        instance.SelectionButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
        instance.SelectionButton:RegisterCallback( Mouse.eLClick,
          function() handler.OnSelectionButtonClicked(selection.Key); end );
      else
        -- It is disabled
        instance.SelectionButton:SetDisabled( true );
        if (selection.FailureReasons ~= nil) then
          instance.SelectionButton:SetToolTipString(Locale.Lookup(selection.FailureReasons[1]));
        end
      end
    end
  end
  Controls.ConversationSelectionStack:CalculateSize();
  Controls.ConversationSelectionStack:ReprocessAnchoring();
  Controls.ConversationSelectionGrid:ReprocessAnchoring();

  -- Update leader response
  Controls.LeaderResponseText:SetText( leaderstr );
  Controls.LeaderResponseText:ReprocessAnchoring();

  -- Update leader reason
  Controls.LeaderReasonText:SetText( reasonStr );
  Controls.LeaderReasonText:ReprocessAnchoring();

  m_currentLeaderAnim = kParsedStatement.LeaderAnimation;
  m_currentSceneEffect = kParsedStatement.SceneEffect;
  local ePlayerMood = DiplomacySupport_GetPlayerMood(ms_SelectedPlayer, ms_LocalPlayerID);

  if (ms_currentViewMode == CONVERSATION_MODE) then
    LeaderSupport_QueueAnimationSequence( ms_OtherLeaderName, kParsedStatement.LeaderAnimation, ePlayerMood );
    LeaderSupport_QueueSceneEffect( kParsedStatement.SceneEffect );
  elseif (ms_currentViewMode == DEAL_MODE) then
    if (ePlayerMood == DiplomacyMoodTypes.HAPPY) then
      LeaderSupport_QueueAnimationSequence( ms_SelectedPlayerLeaderTypeName, "HAPPY_IDLE" );
    elseif (ePlayerMood == DiplomacyMoodTypes.NEUTRAL) then
      LeaderSupport_QueueAnimationSequence( ms_SelectedPlayerLeaderTypeName, "NEUTRAL_IDLE" );
    elseif (ePlayerMood == DiplomacyMoodTypes.UNHAPPY) then
      LeaderSupport_QueueAnimationSequence( ms_SelectedPlayerLeaderTypeName, "UNHAPPY_IDLE" );
    end
  end

end

-- ===========================================================================
function PopulateStatementList( options: table, rootControl: table, isSubList: boolean )
  local buttonIM:table;
  local stackControl:table;
  local selectionText :string = "[SIZE_16]";	-- Resetting the string size for the new button instance
  if (isSubList) then
    buttonIM = ms_ActionListIM;
    stackControl = rootControl.SubOptionsStack;
  else
    buttonIM = ms_SubActionListIM;
    stackControl = rootControl.ContentStack;
  end
  buttonIM:ResetInstances();

  for _, selection in ipairs(options) do
    local instance		:table		= buttonIM:GetInstance(stackControl);
    local selectionText :string		= selectionText.. Locale.Lookup(selection.Text);
    local callback		:ifunction;
    local tooltipString	:string		= nil;
    if( selection.Key ~= nil) then
      callback	= function() OnSelectInitialDiplomacyStatement( selection.Key ) end;

      local pActionDef = GameInfo.DiplomaticActions[selection.DiplomaticActionType];
      if (pActionDef ~= nil and pActionDef.Description ~= nil) then		-- Make sure everything is there, Description is optional!
        local toolTip = pActionDef.Description;
        tooltipString = Locale.Lookup(toolTip);
        instance.Button:SetToolTipString(tooltipString);
      else
        instance.Button:SetToolTipString(nil);		-- Clear any existing
      end

      -- If costs gold add text
      local iCost = GetGoldCost(selection.Key);
      if iCost > 0 then
        local szGoldString = Locale.Lookup("LOC_DIPLO_CHOICE_GOLD_INFO", iCost);
        selectionText = selectionText .. szGoldString;
      end

      -- If war statement add warmongering info
      if (IsWarChoice(selection.Key))then
        local eWarType = GetWarType(selection.Key);
        local iWarmongerPoints = ms_LocalPlayer:GetDiplomacy():ComputeDOWWarmongerPoints(ms_SelectedPlayerID, eWarType);
        local szWarmongerLevel = ms_LocalPlayer:GetDiplomacy():GetWarmongerLevel(-iWarmongerPoints);
        local szWarmongerString = Locale.Lookup("LOC_DIPLO_CHOICE_WARMONGER_INFO", szWarmongerLevel);
        selectionText = selectionText .. szWarmongerString;

        -- Change callback to prompt first.
        callback = function()
          LuaEvents.DiplomacyActionView_ConfirmWarDialog(ms_LocalPlayerID, ms_SelectedPlayerID, eWarType);
        end;
      end
      
      --If denounce statement change callback to prompt first.
      if (selection.Key == "CHOICE_DENOUNCE")then
        local denounceFn = function() OnSelectInitialDiplomacyStatement( selection.Key ); end;
        callback = function() 
          local playerConfig = PlayerConfigurations[ms_SelectedPlayer:GetID()];
          if (playerConfig ~= nil) then

            selectedCivName = Locale.Lookup(playerConfig:GetCivilizationShortDescription());					
            m_PopupDialog:AddText(Locale.Lookup("LOC_DENOUNCE_POPUP_BODY", selectedCivName));
            m_PopupDialog:AddButton(Locale.Lookup("LOC_CANCEL"), nil);
            m_PopupDialog:AddButton(Locale.Lookup("LOC_DIPLO_CHOICE_DENOUNCE"), denounceFn, nil, nil, "PopupButtonInstanceRed");
            m_PopupDialog:Open();

          end
        end;
      end

      instance.ButtonText:SetText( selectionText );
      if (selection.IsDisabled == nil or selection.IsDisabled == false) then
        instance.Button:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
        instance.Button:RegisterCallback( Mouse.eLClick, callback );
        instance.ButtonText:SetColor( COLOR_BUTTONTEXT_NORMAL );
        instance.Button:SetDisabled( false );
      else
        instance.ButtonText:SetColor( COLOR_BUTTONTEXT_DISABLED );
        instance.Button:SetDisabled( true );
        if (selection.FailureReasons ~= nil) then
          instance.Button:SetToolTipString(Locale.Lookup(selection.FailureReasons[1]));
        end
      end

    else
      callback = selection.Callback;
      instance.ButtonText:SetColor( COLOR_BUTTONTEXT_NORMAL );
      instance.Button:SetDisabled( false );
      if ( selection.ToolTip ~= nil) then
        tooltipString = Locale.Lookup(selection.ToolTip);
        instance.Button:SetToolTipString(tooltipString);
      else
        instance.Button:SetToolTipString(nil);		-- Clear any existing
      end
    end

    local wasTruncated :boolean = TruncateString(instance.ButtonText, MAX_BEFORE_TRUNC_BUTTON_INST, selectionText);
    if wasTruncated then
      local finalTooltipString	:string	= selectionText;
      if tooltipString ~= nil then
        finalTooltipString = finalTooltipString .. "[NEWLINE]" .. tooltipString;
      end
      instance.Button:SetToolTipString( finalTooltipString );
    end

    -- Append tooltip string to the end of the tooltip if it exists in this selection
    if selection.Tooltip then
      local currentTooltipString = instance.Button:GetToolTipString();
      instance.Button:SetToolTipString(currentTooltipString .. Locale.Lookup(selection.Tooltip));
    end

        instance.Button:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    instance.Button:RegisterCallback( Mouse.eLClick, callback );
  end
  if (isSubList) then
    local instance		:table		= buttonIM:GetInstance(stackControl);
    selectionText	= selectionText.. Locale.Lookup("LOC_CANCEL_BUTTON");
    instance.ButtonText:SetText( selectionText );
    instance.Button:SetToolTipString(nil);
    instance.Button:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    instance.Button:RegisterCallback( Mouse.eLClick,	function()
                                rootControl.ContentStack:CalculateSize();
                                rootControl.ContentStack:ReprocessAnchoring();
                                rootControl.ContentStack:SetHide(false);
                                rootControl.SubOptionsStack:SetHide(true);
                              end );
  end
  stackControl:CalculateSize();
  stackControl:ReprocessAnchoring();
end

-- ===========================================================================
function AddStatmentOptions(rootControl : table)
  if (ms_LocalPlayerID ~= -1 and ms_SelectedPlayerID ~= -1) then
    local useStatementType = "";
    if (ms_LocalPlayerID ~= ms_SelectedPlayerID) then
      useStatementType = "GREETING";
    else
      useStatementType = "NO_TARGET";
    end

    -- Get the handler for the specific statement we will be using to fill in the initial statements
    -- The normal statement that the initial selections are taken from is the GREETING statement
    -- This usually contains all the possible selections, then they are filtered out if that are not applicable
    -- for the current diplomacy state.
    local handler = GetStatementHandler(useStatementType);
    -- Get the statement options
    local kParsedStatement = handler.ExtractStatement(handler, useStatementType, "NONE", ms_LocalPlayerID, DiplomacyMoodTypes.ANY, DiplomacyInitiatorTypes.HUMAN);
    handler.RemoveInvalidSelections(kParsedStatement, ms_LocalPlayerID, ms_SelectedPlayerID);
    -- Don't need the exit choice at this time
    DiplomacySupport_RemoveSelectionByKey(kParsedStatement, "CHOICE_EXIT");

    ms_ActionListIM:ResetInstances();
    ms_SubActionListIM:ResetInstances();

    local discussOptions:	table = {};
    local warOptions:		table = {};
    local topOptions:		table = {};

    if (kParsedStatement.Selections ~= nil) then
      for _, selection in ipairs(kParsedStatement.Selections) do
        local uiGroup = nil;
        local pActionDef = GameInfo.DiplomaticActions[selection.DiplomaticActionType];
        if (pActionDef ~= nil and pActionDef.UIGroup ~= nil) then		-- Make sure everything is there before accessing!
          uiGroup = pActionDef.UIGroup;
        end

        if ( uiGroup == "DISCUSS") then
          table.insert(discussOptions, selection);
        elseif (uiGroup == "FORMALWAR") then
          table.insert(warOptions, selection);
        else
          table.insert(topOptions, selection)
        end
      end
      if(table.count(discussOptions) > 0) then
        table.insert(topOptions, {
                Text			= Locale.Lookup("LOC_DIPLOMACY_DISCUSS").. " [ICON_List]",
                Callback		=
                  function()
                    rootControl.ContentStack:SetHide(true);
                    rootControl.SubOptionsStack:SetHide(false);
                    PopulateStatementList( discussOptions, rootControl, true );
                  end,
                });
      end
      if(table.count(warOptions) > 0) then
        table.insert(topOptions, {
                Text			= Locale.Lookup("LOC_DIPLOMACY_CASUS_BELLI").. " [ICON_List]",
                Callback		=
                  function()
                    rootControl.ContentStack:SetHide(true);
                    rootControl.SubOptionsStack:SetHide(false);
                    PopulateStatementList( warOptions, rootControl, true );
                  end,
                ToolTip			= "LOC_DIPLOMACY_CASUS_BELLI_TT"
                });
      end
      PopulateStatementList(topOptions, rootControl, false);
    end
    rootControl.ContentStack:CalculateSize();
    rootControl.ContentStack:ReprocessAnchoring();
    rootControl.SubOptionsStack:CalculateSize();
    rootControl.SubOptionsStack:ReprocessAnchoring();
  else
    ms_ActionListIM:ResetInstances();
    ms_SubActionListIM:ResetInstances();
  end
end

-- ===========================================================================
function SetSelectedIntelSubPanelButton(ePanelType, selectedState)

  local intelPanel = ms_IntelPanelIM:GetAllocatedInstance();
  if (intelPanel ~= nil) then
    if (ePanelType == INTEL_ACCESS_LEVEL_PANEL and selectedState == true) then
      SetButtonSelected(intelPanel.AccessLevelButton,true);
    else
      SetButtonSelected(intelPanel.AccessLevelButton,false);
      ms_IntelAccessLevelPanelIM:ResetInstances();
    end

    if (ePanelType == INTEL_RELATIONSHIP_PANEL and selectedState == true) then
      SetButtonSelected(intelPanel.RelationshipButton,true);
    else
      SetButtonSelected(intelPanel.RelationshipButton,false);
      ms_IntelRelationshipPanelIM:ResetInstances();
    end

    if (ePanelType == INTEL_GOSSIP_HISTORY_PANEL and selectedState == true) then
      SetButtonSelected(intelPanel.GossipButton,true);
    else
      SetButtonSelected(intelPanel.GossipButton,false);
      ms_IntelGossipHistoryPanelIM:ResetInstances();
    end

    if (ePanelType == INTEL_AGENDAY_PANEL and selectedState == true) then
    else
      ms_IntelAgendaPanelIM:ResetInstances();
    end
  end
end

-- ===========================================================================
function OnCloseIntelAccessLevelPanel(rootControl)
  OnActivateIntelGossipHistoryPanel(rootControl);
end

-- ===========================================================================
function OnCloseIntelRelationshipPanel(rootControl)
  OnActivateIntelGossipHistoryPanel(rootControl);
end

-- ===========================================================================
function OnCloseIntelAgendaPanel(rootControl)
  OnActivateIntelGossipHistoryPanel(rootControl);
end

-- ===========================================================================
function OnCloseIntelGossipPanel()
  SetSelectedIntelSubPanelButton(INTEL_GOSSIP_HISTORY_PANEL, false);
end

-- ===========================================================================
function OnActivateIntelRelationshipPanel(rootControl : table)

  SetSelectedIntelSubPanelButton(INTEL_RELATIONSHIP_PANEL, true);

  ms_IntelRelationshipPanelIM:ResetInstances();
  local intelSubPanel = ms_IntelRelationshipPanelIM:GetInstance(rootControl);

  -- Get the selected player's Diplomactic AI
  local selectedPlayerDiplomaticAI = ms_SelectedPlayer:GetDiplomaticAI();
  -- What do they think of us?
  local iState = selectedPlayerDiplomaticAI:GetDiplomaticStateIndex(ms_LocalPlayerID);
  local kStateEntry = GameInfo.DiplomaticStates[iState];
  local eState = kStateEntry.Hash;
  intelSubPanel.RelationshipText:LocalizeAndSetText( Locale.ToUpper(kStateEntry.Name) );
  -- Fill the relationship bar to reflect the current status
  local relationshipPercent = 1.0;
  -- If we are at war, show the special flashing red bar
  if (eState == DiplomaticStates.WAR) then
    intelSubPanel.FlashingBar:SetHide(false);
    intelSubPanel.AllyBar:SetHide(true);
    intelSubPanel.WarBar:SetHide(false);
    relationshipPercent = .02;
  elseif (eState == DiplomaticStates.ALLIED) then
    intelSubPanel.FlashingBar:SetHide(false);
    intelSubPanel.AllyBar:SetHide(false);
    intelSubPanel.WarBar:SetHide(true);
    relationshipPercent = .92;
  else
    relationshipPercent = kStateEntry.RelationshipLevel / 100;
    intelSubPanel.FlashingBar:SetHide(true);
  end
  intelSubPanel.RelationshipBar:SetPercent(relationshipPercent);
  intelSubPanel.RelationshipIcon:SetOffsetX(relationshipPercent*intelSubPanel.RelationshipBar:GetSizeX());
  intelSubPanel.RelationshipIcon:SetVisState( GetVisStateFromDiplomaticState(iState) );

  local toolTips = selectedPlayerDiplomaticAI:GetDiplomaticModifiers(ms_LocalPlayerID);
  ms_IntelRelationshipReasonIM:ResetInstances();

  if(toolTips) then
    for i, tip in ipairs(toolTips) do
      local score = tip.Score;
      local text = tip.Text;

      if(score ~= 0) then
        local relationshipReason = ms_IntelRelationshipReasonIM:GetInstance(intelSubPanel.RelationshipReasonStack);

        local scoreText = Locale.Lookup("{1_Score : number +#,###.##;-#,###.##}", score);
        if(score > 0) then
          relationshipReason.Score:SetText("[COLOR_Civ6Green]" .. scoreText .. "[ENDCOLOR]");
        else
          relationshipReason.Score:SetText("[COLOR_Civ6Red]" .. scoreText .. "[ENDCOLOR]");
        end

        if(text == "LOC_TOOLTIP_DIPLOMACY_UNKNOWN_REASON") then
          relationshipReason.Text:SetText("[COLOR_Grey]" .. Locale.Lookup(text) .. "[ENDCOLOR]");
        else
          relationshipReason.Text:SetText(Locale.Lookup(text));
        end
      end
    end
  end

  intelSubPanel.RelationshipReasonStack:CalculateSize();
  intelSubPanel.RelationshipReasonStack:ReprocessAnchoring();
  if(intelSubPanel.RelationshipReasonStack:GetSizeY()==0) then
    intelSubPanel.NoReasons:SetHide(false);
  else
    intelSubPanel.NoReasons:SetHide(true);
  end

  -- Set the advisor icon
  intelSubPanel.AdvisorIcon:SetTexture(IconManager:FindIconAtlas("ADVISOR_GENERIC", 32));

  -- Get the advisor text
  local advisorText = "";
  local selectedCivName = "";
  -- HACK: This is completely faked in for now... Ultimately this list will need to be much smarter
  local playerConfig = PlayerConfigurations[ms_SelectedPlayer:GetID()];
  if (playerConfig ~= nil) then
    selectedCivName = Locale.ToUpper( Locale.Lookup(playerConfig:GetCivilizationDescription()));
  end

  local advisorTextlower = "[COLOR_Grey]";
  advisorTextlower = advisorTextlower .. Locale.Lookup("LOC_DIPLOMACY_ADVISOR_OFFER");
  advisorTextlower = advisorTextlower .. "[NEWLINE]";
--	advisorTextlower = advisorTextlower .. Locale.Lookup("LOC_DIPLOMACY_ADVISOR_DENOUNCE", selectedCivName);
--	advisorTextlower = advisorTextlower .. "[NEWLINE]";
  advisorTextlower = advisorTextlower .. Locale.Lookup("LOC_DIPLOMACY_ADVISOR_TRADE_ROUTE", selectedCivName);
  advisorTextlower = advisorTextlower .. "[NEWLINE]";
  if (not ms_SelectedPlayer:GetDiplomacy():HasOpenBordersFrom(ms_LocalPlayer:GetID())) then
    advisorTextlower = advisorTextlower .. Locale.Lookup("LOC_DIPLOMACY_ADVISOR_OPEN_BORDERS", selectedCivName);
    advisorTextlower = advisorTextlower .. "[NEWLINE]";
  end
  if (not ms_LocalPlayer:GetDiplomacy():HasDelegationAt(ms_SelectedPlayer:GetID()) and not ms_LocalPlayer:GetDiplomacy():HasEmbassyAt(ms_SelectedPlayer:GetID())) then
    advisorTextlower = advisorTextlower .. Locale.Lookup("LOC_DIPLOMACY_ADVISOR_DELEGATION_EMBASSY");
    advisorTextlower = advisorTextlower .. "[NEWLINE]";
  end
  advisorTextlower = advisorTextlower .. Locale.Lookup("LOC_DIPLOMACY_ADVISOR_POSITIVE_AGENDA", selectedCivName);
  advisorTextlower = advisorTextlower .. "[NEWLINE]";
  advisorTextlower = advisorTextlower .. "[ENDCOLOR]";
  local advisorTextRaise = "[COLOR_Grey]";
--	advisorTextRaise = advisorTextRaise .. Locale.Lookup("LOC_DIPLOMACY_ADVISOR_DENOUNCE_FRIEND", selectedCivName);
--	advisorTextRaise = advisorTextRaise .. "[NEWLINE]";
--	advisorTextRaise = advisorTextRaise .. Locale.Lookup("LOC_DIPLOMACY_ADVISOR_DECLARE_FRIENDSHIP", selectedCivName);
--	advisorTextRaise = advisorTextRaise .. "[NEWLINE]";
  advisorTextRaise = advisorTextRaise .. Locale.Lookup("LOC_DIPLOMACY_ADVISOR_NEGATIVE_AGENDA", selectedCivName);
  advisorTextRaise = advisorTextRaise .. "[NEWLINE]";
  advisorTextRaise = advisorTextRaise .. "[ENDCOLOR]";

  intelSubPanel.AdvisorTextRaise:SetText(advisorTextlower);
  intelSubPanel.AdvisorTextLower:SetText(advisorTextRaise);
  intelSubPanel.Advisor:SetHide(false);

  intelSubPanel.Background:SetSizeY(m_bottomPanelHeight);
  intelSubPanel.RelationshipScrollPanel:SetSizeY(m_bottomPanelHeight);
  rootControl:CalculateSize();
  rootControl:ReprocessAnchoring();
  intelSubPanel.RelationshipScrollPanel:CalculateSize();
end

-- ===========================================================================
function OnActivateIntelAccessLevelPanel(rootControl : table)

  SetSelectedIntelSubPanelButton(INTEL_ACCESS_LEVEL_PANEL, true);

  ms_IntelAccessLevelPanelIM:ResetInstances();
  local intelSubPanel = ms_IntelAccessLevelPanelIM:GetInstance(rootControl);

  --intelSubPanel.Close:RegisterCallback( Mouse.eLClick, function() OnCloseIntelAccessLevelPanel(rootControl); end );
  -- Get the selected player's Diplomactic AI
  local selectedPlayerDiplomaticAI = ms_SelectedPlayer:GetDiplomaticAI();

  local localPlayerDiplomacy = ms_LocalPlayer:GetDiplomacy();
  local iAccessLevel = localPlayerDiplomacy:GetVisibilityOn(ms_SelectedPlayerID);

  -- Get the items that contribute to our access level.
  local accessContributionText = "";
  for row in GameInfo.DiplomaticVisibilitySources () do
    if (localPlayerDiplomacy:IsVisibilitySourceActive(ms_SelectedPlayerID, row.Index)) then
      if (row.Description ~= nil) then
        if (#accessContributionText > 0) then
          accessContributionText = accessContributionText .. "[NEWLINE]";
        end
        accessContributionText = accessContributionText .. Locale.Lookup(row.Description);
      end
    end
  end

  if (#accessContributionText > 0) then
    intelSubPanel.AccessContributionText:SetText(accessContributionText);
    intelSubPanel.AccessContribution:SetHide(false);
  else
    intelSubPanel.AccessContribution:SetHide(true);
  end

  -- Access Level button and icon
  intelSubPanel.AccessLevelText:LocalizeAndSetText(Locale.ToUpper(GameInfo.Visibilities[iAccessLevel].Name));
  -- Shift to the correct place in the icon strip, using the vis states.
  intelSubPanel.AccessLevelIcon:SetVisState( iAccessLevel-1 );

  -- Set the information shared string
  local szInfoSharedText = "";
  local iNumAdded = 0;
  for row in GameInfo.Gossips () do
    if (row.VisibilityLevel == iAccessLevel) then
      if (row.Description ~= nil) then
        if (iNumAdded > 0) then
          szInfoSharedText = szInfoSharedText .. "[NEWLINE]";
        end
        szInfoSharedText = szInfoSharedText .. "   " .. Locale.Lookup(row.Description);
        iNumAdded = iNumAdded + 1;
      end
    end
  end

  intelSubPanel.InformationSharedText:SetText(szInfoSharedText);

  -- Set what we will gain at the next access level
  local szNextAccessLevelText = "";
  iNumAdded = 0;
  for row in GameInfo.Gossips () do
    if (row.VisibilityLevel == iAccessLevel + 1) then
      if (row.Description ~= nil) then
        if (iNumAdded > 0) then
          szNextAccessLevelText = szNextAccessLevelText .. "[NEWLINE]";
        end
        szNextAccessLevelText = szNextAccessLevelText .. "   " .. Locale.Lookup(row.Description);
        iNumAdded = iNumAdded + 1;
      end
    end
  end
  intelSubPanel.NextAccessLevelText:SetText(szNextAccessLevelText);

  -- Set the advisor icon
  intelSubPanel.AdvisorIcon:SetTexture(IconManager:FindIconAtlas("ADVISOR_GENERIC", 32));

  -- Get the advisor text
  local advisorText = "";
  for row in GameInfo.DiplomaticVisibilitySources () do
    if (not localPlayerDiplomacy:IsVisibilitySourceActive(ms_SelectedPlayerID, row.Index)) then
      if (row.ActionDescription ~= nil) then
        advisorText = advisorText .. Locale.Lookup(row.ActionDescription).."[NEWLINE]";
      end
    end
  end

  if (#advisorText > 0) then
    intelSubPanel.AdvisorText:SetText(advisorText);
    intelSubPanel.Advisor:SetHide(false);
  else
    intelSubPanel.Advisor:SetHide(true);
  end

  intelSubPanel.Background:SetSizeY(m_bottomPanelHeight);
  intelSubPanel.AccessLevelScrollPanel:SetSizeY(m_bottomPanelHeight);
  rootControl:CalculateSize();
  rootControl:ReprocessAnchoring();
  intelSubPanel.AccessLevelScrollPanel:CalculateSize();
end

-- ===========================================================================
function OnActivateIntelGossipHistoryPanel(rootControl : table)

  SetSelectedIntelSubPanelButton(INTEL_GOSSIP_HISTORY_PANEL, true);
  m_GossipThisTurnCount = 0;
  ms_IntelGossipHistoryPanelIM:ResetInstances();
  local intelSubPanel = ms_IntelGossipHistoryPanelIM:GetInstance(rootControl);

  -- Get the selected player's Diplomactic AI
  local selectedPlayerDiplomaticAI = ms_SelectedPlayer:GetDiplomaticAI();

  local localPlayerDiplomacy = ms_LocalPlayer:GetDiplomacy();

  ms_IntelGossipHistoryPanelEntryIM:ResetInstances();

  local bAddedLastTenTurnsItem = false;
  local bAddedOlderItem = false;

  local gossipManager = Game.GetGossipManager();

  local iCurrentTurn = Game.GetCurrentGameTurn();

  --Only show the gossip generated in the last 100 turns.  Otherwise we can end up with a TON of gossip, and everything bogs down.
  local earliestTurn = iCurrentTurn - 100;
  local gossipStringTable = gossipManager:GetRecentVisibleGossipStrings(earliestTurn, ms_LocalPlayerID, ms_SelectedPlayerID);
    
  if(#gossipStringTable > 0) then								 -- FF16~ Neccesary with new loop to prevent trying to reference items in empty gossip tables of civs you just met.
    --for i, currTable:table in pairs(gossipStringTable) do  -- FF16~ The original loop delcaration seems to have a bug, it puts the most recent gossip entry at the bottom instead of the top. 
    for i = 0, #gossipStringTable do 						 -- FF16~ I have delcared a simpler loop which seems to resolve the issue and correctly puts the list in the right order.
          
      currTable = gossipStringTable[i];		
      local gossipString = currTable[1];
      local gossipTurn = currTable[2];

      if (gossipString ~= nil) then
        local item;
        if ((iCurrentTurn - gossipTurn) <= 10) then
          item = ms_IntelGossipHistoryPanelEntryIM:GetInstance(intelSubPanel.LastTenTurnsStack);
          bAddedLastTenTurnsItem = true;
          if((iCurrentTurn-1) == gossipTurn) then -- FF16~ Originally this is checking if the current turn matches the gossip turn, but its not possible for any gossip to be generated on the active turn. 
            item.NewIndicator:SetHide(false);	-- FF16~ These new gossip entry highlight icons would never be show as a result! Fixed by checking against previous turn instead.
            m_GossipThisTurnCount = m_GossipThisTurnCount + 1; 
          else
            item.NewIndicator:SetHide(true);
          end
        else
          item = ms_IntelGossipHistoryPanelEntryIM:GetInstance(intelSubPanel.OlderStack);
          bAddedOlderItem = true;
        end

        if (item ~= nil) then
          -- AZURENCY : trim the message if the setting is enable
          if(CQUI_trimGossip) then
            gossipString = CQUI_TrimGossipMessage(gossipString);
          end
          item.GossipText:SetText(gossipString);			-- It has already been localized
          AutoSizeGrid(item:GetTopControl(), item.GossipText,25,25);
        end
      else
        break;
      end
    end
  end
    
  if (not bAddedLastTenTurnsItem) then
    local item = ms_IntelGossipHistoryPanelEntryIM:GetInstance(intelSubPanel.LastTenTurnsStack);
    item.GossipText:LocalizeAndSetText("LOC_DIPLOMACY_GOSSIP_ITEM_NO_RECENT");
    item.NewIndicator:SetHide(true);
    AutoSizeGrid(item:GetTopControl(), item.GossipText,25,37);
  end

  if (not bAddedOlderItem) then
    intelSubPanel.OlderHeader:SetHide(true);
  else
    intelSubPanel.OlderHeader:SetHide(false);
  end

  intelSubPanel.Background:SetSizeY(m_bottomPanelHeight);
  intelSubPanel.GossipScrollPanel:SetSizeY(m_bottomPanelHeight);
  rootControl:CalculateSize();
  rootControl:ReprocessAnchoring();
  intelSubPanel.GossipScrollPanel:CalculateSize();
end
-- ===========================================================================
function AutoSizeGrid(gridControl: table, labelControl: table, padding:number, minSize:number)
  local sizeY: number = labelControl:GetSizeY() + padding;
  if (sizeY < minSize) then
    sizeY = minSize;
  end
  gridControl:SetSizeY(sizeY);
end

-- ===========================================================================
function AddIntelPanel(rootControl : table)

  SetSelectedIntelSubPanelButton(INTEL_NO_SUB_PANEL, false);

  ms_IntelPanelIM:ResetInstances();

  if (ms_LocalPlayerID ~= -1 and ms_SelectedPlayerID ~= -1 and ms_LocalPlayerID ~= ms_SelectedPlayerID) then

    local intelPanel = ms_IntelPanelIM:GetInstance(rootControl);

    local localPlayerDiplomacy = ms_LocalPlayer:GetDiplomacy();
    local iAccessLevel = localPlayerDiplomacy:GetVisibilityOn(ms_SelectedPlayerID);

    -- Gossip button
    intelPanel.GossipButton:RegisterCallback( Mouse.eLClick, function() OnActivateIntelGossipHistoryPanel(rootControl); end );
        intelPanel.GossipButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    SetButtonSelected( intelPanel.GossipButton, true);

    -- Access Level button and icon
    intelPanel.AccessLevelText:LocalizeAndSetText(GameInfo.Visibilities[iAccessLevel].Name);
    -- Shift to the correct place in the icon strip, using the vis states.
    if( iAccessLevel == 0) then
      intelPanel.AccessLevelIcon:SetHide(true);
    else
      intelPanel.AccessLevelIcon:SetHide(false);
      intelPanel.AccessLevelIcon:SetVisState( iAccessLevel-1 );
    end
    intelPanel.AccessLevelButton:RegisterCallback( Mouse.eLClick, function() OnActivateIntelAccessLevelPanel(rootControl); end );
        intelPanel.AccessLevelButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    SetButtonSelected(intelPanel.AccessLevelButton, false);

    -- Relationship Panel Button
    if (PlayerConfigurations[ms_SelectedPlayerID]:IsHuman()) then
      -- Don't show any calculated relationship with a human
      intelPanel.RelationshipStack:SetHide(true);
    else
      intelPanel.RelationshipStack:SetHide(false);
      intelPanel.RelationshipButton:RegisterCallback( Mouse.eLClick, function() OnActivateIntelRelationshipPanel(rootControl); end );
            intelPanel.RelationshipButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
      SetButtonSelected(intelPanel.RelationshipButton, false);

      -- Get the selected player's Diplomactic AI
      local selectedPlayerDiplomaticAI = ms_SelectedPlayer:GetDiplomaticAI();
      -- What do they think of us?
      local iState :number = selectedPlayerDiplomaticAI:GetDiplomaticStateIndex(ms_LocalPlayerID);
      local relationshipString:string = Locale.Lookup(GameInfo.DiplomaticStates[iState].Name);
      -- Add team name to relationship text for our own teams
      if Players[ms_LocalPlayerID]:GetTeam() == Players[ms_SelectedPlayerID]:GetTeam() then
        relationshipString = "(" .. Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", Players[ms_LocalPlayerID]:GetTeam()) .. ") " .. relationshipString;
      end
      intelPanel.RelationshipText:SetText( relationshipString );

      if (GameInfo.DiplomaticStates[iState].StateType == "DIPLO_STATE_DENOUNCED") then
          local szDenounceTooltip;
        local iRemainingTurns;
        local iOurDenounceTurn = localPlayerDiplomacy:GetDenounceTurn(ms_SelectedPlayerID);
        local iTheirDenounceTurn = Players[ms_SelectedPlayerID]:GetDiplomacy():GetDenounceTurn(ms_LocalPlayerID);

        -- *** REPLACE GOSSIP STRING WHEN POSSIBLE -- SHOULD BE STORED WITH DIPLO STRINGS ***
        if (iOurDenounceTurn >= iTheirDenounceTurn) then
            iRemainingTurns = iOurDenounceTurn + GlobalParameters.DIPLOMACY_DENOUNCE_TIME_LIMIT - Game.GetCurrentGameTurn();
          szDenounceTooltip = Locale.Lookup("LOC_GOSSIP_DENOUNCED", PlayerConfigurations[ms_LocalPlayerID]:GetCivilizationShortDescription(), PlayerConfigurations[ms_SelectedPlayerID]:GetCivilizationShortDescription());
        else
            iRemainingTurns = iTheirDenounceTurn + GlobalParameters.DIPLOMACY_DENOUNCE_TIME_LIMIT - Game.GetCurrentGameTurn();
          szDenounceTooltip = Locale.Lookup("LOC_GOSSIP_DENOUNCED", PlayerConfigurations[ms_SelectedPlayerID]:GetCivilizationShortDescription(), PlayerConfigurations[ms_LocalPlayerID]:GetCivilizationShortDescription());
        end
        szDenounceTooltip = szDenounceTooltip .. " [" .. Locale.Lookup("LOC_ESPIONAGEPOPUP_TURNS_REMAINING", iRemainingTurns) .. "]";
        intelPanel.RelationshipText:SetToolTipString(szDenounceTooltip);
      else
        intelPanel.RelationshipText:SetToolTipString(nil);
      end
      intelPanel.RelationshipIcon:SetVisState(GetVisStateFromDiplomaticState(iState));
      -- IF the Diplomacy State is Neutral, hide the icon, otherwise, display.
      if (GameInfo.DiplomaticStates[iState].Hash == DiplomaticStates.NEUTRAL ) then
        intelPanel.RelationshipIcon:SetHide(true);
      else
        intelPanel.RelationshipIcon:SetHide(false);
      end
      intelPanel.RelationshipStack:CalculateSize();
      intelPanel.RelationshipStack:ReprocessAnchoring();
    end

    ms_IconOnlyIM:ResetInstances();
    intelPanel.AgreementsOuterStack:SetHide(false);
    intelPanel.AgreementStack:SetHide(false);
    local AGREEMENT_TYPES: table = {DIPLO_DELEGATION = "DIPLOACTION_DIPLOMATIC_DELEGATION",
                    RESIDENT_EMBASSY = "DIPLOACTION_RESIDENT_EMBASSY",
                    DEFENSIVE_PACT = "DIPLOACTION_DEFENSIVE_PACT",
                    OPEN_BORDERS = "DIPLOACTION_OPEN_BORDERS",
                    RESEARCH_AGREEMENT = "DIPLOACTION_RESEARCH_AGREEMENT",
                    JOINT_WAR = "DIPLOACTION_JOINT_WAR"};

    if (localPlayerDiplomacy:HasDelegationAt(ms_SelectedPlayer:GetID())) then
      local agreement = ms_IconOnlyIM:GetInstance(intelPanel.AgreementStack);
      local type = AGREEMENT_TYPES.DIPLO_DELEGATION;
      agreement.Icon:SetIcon("ICON_"..type);
      agreement.Icon:SetToolTipString(Locale.Lookup("LOC_DIPLO_MODIFIER_DELEGATION"));
    end
    if(localPlayerDiplomacy:HasEmbassyAt(ms_SelectedPlayer:GetID())) then
      local agreement = ms_IconOnlyIM:GetInstance(intelPanel.AgreementStack);
      local type = AGREEMENT_TYPES.RESIDENT_EMBASSY;
      agreement.Icon:SetIcon("ICON_"..type);
      agreement.Icon:SetToolTipString(Locale.Lookup("LOC_DIPLO_MODIFIER_RESIDENT_EMBASSY"));
    end
    if(localPlayerDiplomacy:HasDefensivePact(ms_SelectedPlayer:GetID())) then
      local agreement = ms_IconOnlyIM:GetInstance(intelPanel.AgreementStack);
      local type = AGREEMENT_TYPES.DEFENSIVE_PACT;
      agreement.Icon:SetIcon("ICON_"..type);
      agreement.Icon:SetToolTipString(Locale.Lookup("LOC_DIPLO_MODIFIER_DEFENSIVE_PACT"));
    end
    if(localPlayerDiplomacy:HasOpenBordersFrom(ms_SelectedPlayer:GetID())) then
      local agreement = ms_IconOnlyIM:GetInstance(intelPanel.AgreementStack);
      local type = AGREEMENT_TYPES.OPEN_BORDERS;
      agreement.Icon:SetIcon("ICON_"..type);
      agreement.Icon:SetToolTipString(Locale.Lookup("LOC_DIPLO_MODIFIER_OPEN_BORDERS"));
    end
    if(localPlayerDiplomacy:GetResearchAgreementTech(ms_SelectedPlayer:GetID()) ~= -1) then
      local agreement = ms_IconOnlyIM:GetInstance(intelPanel.AgreementStack);
      local type = AGREEMENT_TYPES.RESEARCH_AGREEMENT;
      agreement.Icon:SetIcon("ICON_"..type);
      agreement.Icon:SetToolTipString(Locale.Lookup("LOC_DIPLOACTION_RESEARCH_AGREEMENT_NAME"));
      print(agreement.Icon:GetSizeX());
      print(agreement.Icon:GetSizeY());
    end
    if(localPlayerDiplomacy:IsFightingAnyJointWarWith(ms_SelectedPlayer:GetID())) then
      local agreement = ms_IconOnlyIM:GetInstance(intelPanel.AgreementStack);
      local type = AGREEMENT_TYPES.JOINT_WAR;
      agreement.Icon:SetIcon("ICON_"..type);
      agreement.Icon:SetToolTipString(Locale.Lookup("LOC_DIPLOACTION_JOINT_WAR_NAME"));
    end

    intelPanel.AgreementStack:CalculateSize();
    intelPanel.AgreementStack:ReprocessAnchoring();
    if(intelPanel.AgreementStack:GetSizeX() == 0) then
      intelPanel.AgreementsOuterStack:SetHide(true);
    else
      intelPanel.AgreementsOuterStack:SetHide(false);
    end

    ms_TextOnlyIM:ResetInstances();
    if (PlayerConfigurations[ms_SelectedPlayerID]:IsHuman()) then
      -- Humans don't have agendas, at least ones we can show
      intelPanel.AgendaOuterStack:SetHide(true);
    else
      intelPanel.AgendaOuterStack:SetHide(false);
      -- What Historical Agenda does the selected player have?
      local leader:string = PlayerConfigurations[ms_SelectedPlayerID]:GetLeaderTypeName();
      local hasHistoricalAgenda = true;
      if GameInfo.HistoricalAgendas[leader] ~= nil then
        local agendaType = GameInfo.HistoricalAgendas[leader].AgendaType;
        local historicalAgenda = ms_TextOnlyIM:GetInstance(intelPanel.AgendaStack);
        historicalAgenda.Text:LocalizeAndSetText( GameInfo.Agendas[agendaType].Name );
        historicalAgenda.Text:LocalizeAndSetToolTip( GameInfo.Agendas[agendaType].Description );
      else
        hasHistoricalAgenda = false;
      end

      -- What randomly assigned agendas does the selected player have?
      -- Determine whether our Diplomatic Visibility allows us to see random agendas
      local bRevealRandom = false;
      for row in GameInfo.Visibilities() do
        if (row.Index <= iAccessLevel and row.RevealAgendas == true) then
          bRevealRandom = true;
        end
      end
      local kAgendaTypes = {};
      kAgendaTypes = ms_SelectedPlayer:GetAgendaTypes();
      --GetAgendaTypes() returns ALL of my agendas, including the historical agenda.
      --To retrieve only the randomly assigned agendas, delete the first entry from the table.
      table.remove(kAgendaTypes,1);
      local numRandomAgendas = table.count(kAgendaTypes);
      if (numRandomAgendas > 0) then
        if(bRevealRandom) then
          -- If our visibility allows, display the agendas
          -- At present, we are displaying ALL random agendas, if we have reached the SECRET level.
          local bFirst = true;
          for i, agendaType in ipairs(kAgendaTypes) do
            local randomAgenda = ms_TextOnlyIM:GetInstance(intelPanel.AgendaStack);
            randomAgenda.Text:LocalizeAndSetText( GameInfo.Agendas[agendaType].Name );
            randomAgenda.Text:LocalizeAndSetToolTip( GameInfo.Agendas[agendaType].Description );
          end
        else
          --Otherwise, display that how many hidden agendas there are, and incentivize player to gain visibility to see them!
          local hiddenAgenda = ms_TextOnlyIM:GetInstance(intelPanel.AgendaStack);
          hiddenAgenda.Text:LocalizeAndSetText("LOC_DIPLOMACY_HIDDEN_AGENDAS",numRandomAgendas, numRandomAgendas>1);
          hiddenAgenda.Text:LocalizeAndSetToolTip("LOC_DIPLOMACY_HIDDEN_AGENDAS_TT");
        end
      elseif (numRandomAgendas == 0) then
        local noRandomAgendas = ms_TextOnlyIM:GetInstance(intelPanel.AgendaStack);
        noRandomAgendas.Text:LocalizeAndSetText("LOC_DIPLOMACY_RANDOM_AGENDA_NONE");
      end
    end

    -- What Government does the selected player have?
    local eSelectePlayerGovernment :number = ms_SelectedPlayer:GetCulture():GetCurrentGovernment();
    if eSelectePlayerGovernment ~= -1 then
      intelPanel.GovernmentText:LocalizeAndSetText( GameInfo.Governments[eSelectePlayerGovernment].Name );
    else
        intelPanel.GovernmentText:LocalizeAndSetText( "LOC_GOVERNMENT_ANARCHY_NAME" );
    end

    --Set data for relationship area
    local selectedPlayerConfig = PlayerConfigurations[ms_SelectedPlayer:GetID()];
    local leaderDesc = selectedPlayerConfig:GetLeaderName();
    --intelPanel.TheirRelationships:SetText(Locale.Lookup(leaderDesc).."'s Relationships");
    ms_RelationshipIconsIM:ResetInstances();
    -- Get who the selected player has met
    local selectedPlayerDiplomacy = ms_SelectedPlayer:GetDiplomacy();
    --Does GetPlayersMet necessarily give me the correct thing?...
    --local aPlayers = selectedPlayerDiplomacy:GetPlayersMet();
    local aPlayers = PlayerManager.GetAliveMajors();
    for _, pPlayer in ipairs(aPlayers) do
      if (pPlayer:IsMajor() and pPlayer:GetID() ~= ms_LocalPlayerID and pPlayer:GetID() ~= ms_SelectedPlayer:GetID() and selectedPlayerDiplomacy:HasMet(pPlayer:GetID())) then
        local playerConfig = PlayerConfigurations[pPlayer:GetID()];
        local leaderTypeName = playerConfig:GetLeaderTypeName();
        if (leaderTypeName ~= nil) then
          local relationshipIcon = ms_RelationshipIconsIM:GetInstance(intelPanel.RelationshipsStack);
          local iPlayerDiploState = pPlayer:GetDiplomaticAI():GetDiplomaticStateIndex(ms_SelectedPlayer:GetID());
          relationshipIcon.Status:SetVisState( iPlayerDiploState );
          local relationshipState = GameInfo.DiplomaticStates[iPlayerDiploState];
          -- No diplo state icon if both players are human, except for the war state
          if ( ((ms_SelectedPlayer:IsAI() or pPlayer:IsAI()) and relationshipState.Hash ~= DiplomaticStates.NEUTRAL) or IsValidRelationship(relationshipState.StateType)) then
            relationshipIcon.Status:SetToolTipString(Locale.Lookup(GameInfo.DiplomaticStates[iPlayerDiploState].Name));
          end
          if(localPlayerDiplomacy:HasMet(pPlayer:GetID())) then
            relationshipIcon.Icon:SetTexture(IconManager:FindIconAtlas("ICON_" .. playerConfig:GetLeaderTypeName(), 32));
            -- Tool tip
            local leaderDesc = playerConfig:GetLeaderName();
            relationshipIcon.Background:LocalizeAndSetToolTip("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE", leaderDesc, playerConfig:GetCivilizationDescription());

            -- Show team ribbon for ourselves and civs we've met
            local teamID:number = playerConfig:GetTeam();
            if #Teams[teamID] > 1 then
              local teamRibbonName:string = TEAM_RIBBON_PREFIX .. tostring(teamID);
              relationshipIcon.TeamRibbon:SetIcon(teamRibbonName, TEAM_RIBBON_SMALL_SIZE);
              relationshipIcon.TeamRibbon:SetHide(false);
              relationshipIcon.TeamRibbon:SetColor(GetTeamColor(teamID));
            else
              -- Hide team ribbon if team only contains one player
              relationshipIcon.TeamRibbon:SetHide(true);
            end
          else
            -- IF the local player has not met the civ that this civ has a relationship, do not reveal that information through this icon.  Instead, set to generic leader and "Unmet Civ"
            relationshipIcon.Icon:SetTexture(IconManager:FindIconAtlas("ICON_LEADER_DEFAULT", 32));
            relationshipIcon.Background:LocalizeAndSetToolTip("LOC_DIPLOPANEL_UNMET_PLAYER");
            relationshipIcon.TeamRibbon:SetHide(true);
          end
        end
      end
    end
    intelPanel.RelationshipsStack:CalculateSize();
    intelPanel.RelationshipsStack:ReprocessAnchoring();
    --IF this civ hasn't met anyone but you, hide the relationship stack
    if ( intelPanel.RelationshipsStack:GetSizeY() == 0) then
      intelPanel.RelationshipSectionStack:SetHide(true);
    else
      intelPanel.RelationshipSectionStack:SetHide(false);
    end
    -- Calculate the size of the scrollpanel
    rootControl:CalculateSize();
    rootControl:ReprocessAnchoring();
    local _, screenY:number = UIManager:GetScreenSizeVal();
    m_bottomPanelHeight = screenY - rootControl:GetSizeY() - PADDING_FOR_SCROLLPANEL;
    -- Default to showing the Gossip History
    OnActivateIntelGossipHistoryPanel(rootControl);
    if (m_GossipThisTurnCount > 0) then
      intelPanel.GossipText:SetText(Locale.Lookup("LOC_DIPLOMACY_GOSSIP_ITEM_COUNT", m_GossipThisTurnCount));
    else
      intelPanel.GossipText:SetText(Locale.Lookup("LOC_DIPLOMACY_GOSSIP_ITEM_NONE_THIS_TURN"));
    end
  end
end
-- ===========================================================================
function PopulatePlayerPanel(rootControl : table, player : table)

  if (player ~= nil) then
    AddStatmentOptions(rootControl);
    AddIntelPanel(rootControl.ContentStack);
    rootControl.RootStack:CalculateSize();
    rootControl.RootStack:ReprocessAnchoring();
  end
end

-- ===========================================================================
function PopulatePlayerPanelHeader(rootControl : table, player : table)

  if (player ~= nil) then
    local playerConfig = PlayerConfigurations[player:GetID()];
    if (playerConfig ~= nil) then
      -- Set the icon
      rootControl.LeaderIcon:SetIcon("ICON_" .. playerConfig:GetLeaderTypeName());
      -- Set the leader name
      local leaderDesc = playerConfig:GetLeaderName();
      rootControl.PlayerNameText:LocalizeAndSetText( Locale.ToUpper( Locale.Lookup(leaderDesc)));
      rootControl.CivNameText:LocalizeAndSetText( Locale.ToUpper( Locale.Lookup(playerConfig:GetCivilizationDescription())));

    end
  end
end

-- ===========================================================================
function PopulateLeader(leaderIcon : table, player : table, isUniqueLeader : boolean)

  if (player ~= nil and player:IsMajor()) then
    local playerID = player:GetID();
    local playerConfig = PlayerConfigurations[playerID];
    if (playerConfig ~= nil) then
      local leaderTypeName = playerConfig:GetLeaderTypeName();
      if (leaderTypeName ~= nil) then

        local iconName = "ICON_" .. leaderTypeName;
        leaderIcon:UpdateIcon(iconName, playerID, isUniqueLeader);
        
        -- Configure button
        leaderIcon.Controls.SelectButton:SetVoid1(playerID);
        leaderIcon:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
        leaderIcon:RegisterCallback(Mouse.eLClick, OnPlayerSelected);

        -- Set the score.
        leaderIcon.Controls.Score:SetText( tostring( player:GetScore() ) );
        -- Set the gold per turn
        local goldYield = player:GetTreasury():GetGoldYield();
        if (goldYield > 0) then
          leaderIcon.Controls.GoldPerTurn:SetText( "(+" .. string.format("%.1f", goldYield) .. " [ICON_Gold])" );			
        else
          leaderIcon.Controls.GoldPerTurn:SetText( "(" .. string.format("%.1f", goldYield) .. " [ICON_Gold])" );			
        end
        -- The selection background
        leaderIcon.Controls.SelectedBackground:SetHide(playerID ~= ms_SelectedPlayerID);
      end
    end
  end
end

-- ===========================================================================
function SetConversationMode(player : table)

  Controls.ConversationContainer:SetHide(false);
  Controls.LeaderResponse_Alpha:Play();
  Controls.ConversationSelection_Alpha:Play();
  Controls.LeaderResponse_Slide:Play();
  Controls.ConversationSelection_Slide:Play();

  Controls.OverviewContainer:SetHide(true);

  ms_currentViewMode = CONVERSATION_MODE;

end

-- ===========================================================================
--	Centers scroll panel (if possible) on a specfic type.
-- ===========================================================================
function ScrollToNode( playerID:number )
  local percent:number = 0;
  local scrollHeight = ms_DiplomacyRibbon.LeaderRibbonScroll:GetSizeY();
  if (m_LeaderCoordinates ~= nil) and (m_LeaderCoordinates[playerID] ~= nil) then
    local y		= m_LeaderCoordinates[playerID] - ( scrollHeight * 0.4);
    local size  = (scrollHeight / ms_DiplomacyRibbon.LeaderRibbonScroll:GetRatio()) - scrollHeight;
    percent = math.clamp( y  / size, 0, 1);
  end
  ms_DiplomacyRibbon.LeaderRibbonScroll:SetScrollValue(percent);
end

-- ===========================================================================
function SelectPlayer(playerID, mode, refresh, allowDeadPlayer)
  if (mode == nil) then
    mode = ms_currentViewMode;
  end
  if (refresh == nil) then
    refresh = false;
  end

  if (allowDeadPlayer == nil) then
    allowDeadPlayer = false;
  end

  local isDifferentPlayer = false;
  if (ms_SelectedPlayerID ~= playerID or mode ~= ms_currentViewMode or refresh == true) then

    isDifferentPlayer = true;

    -- Deselect them in the ribbon
    if (ms_SelectedPlayerID ~= -1) then
      local ribbonEntry = ms_LeaderIDToRibbonEntry[ms_SelectedPlayerID];
      if (ribbonEntry ~= nil) then
        ribbonEntry.SelectedBackground:SetHide( true );
      end
    end

    if (m_firstOpened == false) then
      if (ms_SelectedPlayerID == playerID) then
        isDifferentPlayer = false;
      end
    end
    ms_SelectedPlayerID = playerID;

    UpdateSelectedPlayer(allowDeadPlayer);		-- Make sure it is valid

    if (ms_SelectedPlayerID ~= -1) then
      local ribbonEntry = ms_LeaderIDToRibbonEntry[ms_SelectedPlayerID];
      if (ribbonEntry ~= nil) then -- can select a dead player, so check for nil
        ribbonEntry.SelectedBackground:SetHide( false );
      end

      if(ms_SelectedPlayerID ~= ms_LocalPlayerID) then
        PopulatePlayerPanelHeader(ms_PlayerPanel, ms_SelectedPlayer);
        PopulatePlayerPanel(ms_PlayerPanel, ms_SelectedPlayer);
      end
      Controls.LeaderAnchor:SetHide(false);

      -- If we are switching from one mode into another, show and hide the appropriate controls/ set the appropriate data
      if (ms_currentViewMode ~= mode or refresh) then
        if (mode == CONVERSATION_MODE) then
          SetConversationMode(ms_SelectedPlayer);
        elseif (mode == CINEMA_MODE) then
          -- If we are switching into CINEMA_MODE.. we have to wait to update our displays until AFTER the fade-down.
          -- FadeTimeAnim has an end callback registered to function "ToggleCinemaMode"
          if (ContextPtr:IsHidden()) then
            -- Unless the context is hidden, in which case we will go directly into cinema mode when the context is showm
            m_cinemaMode = true;
          else
            StartFadeOut();
          end
        elseif (mode == OVERVIEW_MODE) then
          Controls.ConversationContainer:SetHide(true);
          Controls.OverviewContainer:SetHide(false);
          Controls.VoiceoverTextContainer:SetHide(true);
          if (not m_firstOpened) then
            Controls.AlphaIn:SetSpeed(3);
            Controls.SlideIn:SetSpeed(3);
            Controls.AlphaIn:SetPauseTime(0);
            Controls.SlideIn:SetPauseTime(0);
            Controls.SlideIn:SetBeginVal(-20,0);
          end
          Controls.AlphaIn:SetToBeginning();
          Controls.SlideIn:SetToBeginning();
          Controls.AlphaIn:Play();
          Controls.SlideIn:Play();
          UI.PlaySound("UI_Diplomacy_Open_Long");
        end
        ms_currentViewMode = mode;
      end
      ShowLeader(ms_SelectedPlayer);
    end
  end
  if (isDifferentPlayer and ms_SelectedPlayerID ~= ms_LocalPlayerID) then
    LuaEvents.DiploScene_LeaderSelect(playerID);
  end
  m_firstOpened = false;
  local w,h = UIManager:GetScreenSizeVal();
  -- Set up special display if the player is YOU
  if(ms_SelectedPlayerID == ms_LocalPlayerID) then
    Controls.NameFade:SetHide(false);
    local playerConfig = PlayerConfigurations[ms_LocalPlayerID];
    if (playerConfig ~= nil) then
      -- Set the leader name
      Controls.NameFade:SetToBeginning();
      Controls.NameFade:Play();
      Controls.NameSlide:SetToBeginning();
      Controls.NameSlide:Play();
      local leaderDesc = playerConfig:GetLeaderName();
      Controls.PlayerNameText:LocalizeAndSetText( Locale.ToUpper( Locale.Lookup(leaderDesc)));
      Controls.CivNameText:LocalizeAndSetText( Locale.ToUpper( Locale.Lookup(playerConfig:GetCivilizationDescription())));
      SetUniqueCivLeaderData();
    end
    Controls.PlayerContainer:SetHide(true);

    --Controls.LeaderAnchor:SetOffsetX(w - (w/2.5));
    UI.SetLeaderPosition(Controls.LeaderAnchor:GetScreenOffset());
    LuaEvents.DiploScene_CinemaSequence(ms_SelectedPlayerID);
  else
    Controls.NameFade:SetHide(true);
    Controls.PlayerContainer:SetHide(false);
    Controls.LeaderAnchor:SetOffsetX(w - (w/3.5));
    UI.SetLeaderPosition(Controls.LeaderAnchor:GetScreenOffset());
  end
end

function SetUniqueCivLeaderData()
-- Obtain "uniques" from Civilization and for the chosen leader
  ms_uniqueIconIM:ResetInstances();
  ms_uniqueTextIM:ResetInstances();

  local playerConfig		:table = PlayerConfigurations[ms_LocalPlayerID];
  local civType	:string = playerConfig:GetCivilizationTypeName();
  local leaderType	:string = playerConfig:GetLeaderTypeName();
  local uniqueAbilities;
  local uniqueUnits;
  local uniqueBuildings;
  uniqueAbilities, uniqueUnits, uniqueBuildings = GetLeaderUniqueTraits( leaderType );
  local CivUniqueAbilities, CivUniqueUnits, CivUniqueBuildings = GetCivilizationUniqueTraits( civType );

  -- Merge tables
  for i,v in ipairs(CivUniqueAbilities)	do table.insert(uniqueAbilities, v) end
  for i,v in ipairs(CivUniqueUnits)		do table.insert(uniqueUnits, v)		end
  for i,v in ipairs(CivUniqueBuildings)	do table.insert(uniqueBuildings, v) end

  -- Generate content
  for _, item in ipairs(uniqueAbilities) do
    local instance:table = {};
    instance = ms_uniqueTextIM:GetInstance();
    local headerText:string = Locale.ToUpper(Locale.Lookup( item.Name ));
    instance.Header:SetText( headerText );
    instance.Description:SetText( Locale.Lookup( item.Description ) );
  end

  local size:number = SIZE_BUILDING_ICON;

  for _, item in ipairs(uniqueUnits) do
    local instance:table = {};
    instance = ms_uniqueIconIM:GetInstance();
    iconAtlas = "ICON_"..item.Type;
    instance.Icon:SetIcon(iconAtlas);
    instance.TextStack:SetOffsetX( size + 4 );
    local headerText:string = Locale.ToUpper(Locale.Lookup( item.Name ));
    instance.Header:SetText( headerText );
    instance.Description:SetText(Locale.Lookup(item.Description));
  end


  for _, item in ipairs(uniqueBuildings) do
    local instance:table = {};
    instance = ms_uniqueIconIM:GetInstance();
    instance.Icon:SetSizeVal(38,38);
    iconAtlas = "ICON_"..item.Type;
    instance.Icon:SetIcon(iconAtlas);
    instance.TextStack:SetOffsetX( size + 4 );
    local headerText:string = Locale.ToUpper(Locale.Lookup( item.Name ));
    instance.Header:SetText( headerText );
    instance.Description:SetText(Locale.Lookup(item.Description));
  end

  Controls.UniqueInfoStack:CalculateSize();
  Controls.UniqueInfoStack:ReprocessAnchoring();
end
-- ===========================================================================
function OnPlayerSelected(playerID)
  if (HasCapability("CAPABILITY_DIPLOMACY") or (playerID == Game.GetLocalPlayer() and HasCapability("CAPABILITY_DIPLOMACY_VIEW_SELF"))) then
    ResetPlayerPanel();
    SelectPlayer(playerID);
  end
end

-- ===========================================================================
function PopulateDiplomacyRibbon(diplomacyRibbon : table)

  if (ms_LocalPlayer ~= nil) then
    local pLocalPlayerDiplomacy = ms_LocalPlayer:GetDiplomacy();
    ms_DiplomacyRibbonLeaderIM:ResetInstances();
    ms_LeaderIDToRibbonEntry = {};
    local currentCoordinateY = 32;
    local coordinateOffsetIncrement = 64;

    -- Set the advisor icon
    -- diplomacyRibbon.Advisor:SetTexture(IconManager:FindIconAtlas("ADVISOR_GENERIC", 48));

    -- Add an entry for the local player at the top
    local leaderIcon, leaderInstance = LeaderIcon:GetInstance(ms_DiplomacyRibbonLeaderIM, diplomacyRibbon.Leaders);
    ms_LeaderIDToRibbonEntry[ms_LocalPlayerID] = leaderInstance;
    PopulateLeader(leaderIcon, ms_LocalPlayer);

    --Then, let's do a check to see if any of these players are duplicate leaders and track it.
    --		Must go through entire list to detect duplicates (would be lovely if we had an IsUnique from PlayerConfigurations)
    local isUniqueLeader: table = {};
    local aPlayers = PlayerManager.GetAliveMajors();
    for _, pPlayer in ipairs(aPlayers) do
      local playerID:number = pPlayer:GetID();
      if(playerID ~= ms_LocalPlayer) then
        local leaderName:string = PlayerConfigurations[playerID]:GetLeaderTypeName();
        if (isUniqueLeader[leaderName] == nil) then
          isUniqueLeader[leaderName] = true;
        else
          isUniqueLeader[leaderName] = false;
        end
      end
    end

    -- Add entries for everyone we know (Majors only)
    local aPlayers = PlayerManager.GetAliveMajors();
    for _, pPlayer in ipairs(aPlayers) do
      if (pPlayer:GetID() ~= ms_LocalPlayerID and pLocalPlayerDiplomacy:HasMet(pPlayer:GetID())) then
        local leaderIcon, leaderInstance = LeaderIcon:GetInstance(ms_DiplomacyRibbonLeaderIM, diplomacyRibbon.Leaders);
        ms_LeaderIDToRibbonEntry[pPlayer:GetID()] = leaderInstance;
        -- Save the current coordinate in the scrollpanel so that we can autoscroll to this point later
        m_LeaderCoordinates[pPlayer:GetID()] = currentCoordinateY;
        currentCoordinateY = currentCoordinateY + coordinateOffsetIncrement;
        local leaderName:string = PlayerConfigurations[pPlayer:GetID()]:GetLeaderTypeName();
        if(isUniqueLeader[leaderName] ~= nil) then
          PopulateLeader(leaderIcon, pPlayer, isUniqueLeader[leaderName]);
        else
          PopulateLeader(leaderIcon, pPlayer);
        end
      end
    end

    -- Rebuild the stack
    diplomacyRibbon.Leaders:CalculateSize();
    diplomacyRibbon.Leaders:ReprocessAnchoring();
    diplomacyRibbon.LeaderRibbonScroll:CalculateSize();
    diplomacyRibbon.Root:ReprocessAnchoring();

    -- Offset the diplomacy ribbon to accomodate the scrollbar if not all the leaders fit
    if(diplomacyRibbon.Leaders:GetSizeY() > diplomacyRibbon.LeaderRibbonScroll:GetSizeY()) then
      diplomacyRibbon.Root:SetOffsetX(15);
    end
    local offsetX = DIPLOMACY_RIBBON_OFFSET + diplomacyRibbon.Root:GetOffsetX();
    Controls.PlayerContainer:SetOffsetX(offsetX);
    Controls.NameFade:SetOffsetX(offsetX);
    --Controls.OverviewContainer:SetOffsetX(offsetX);
  end

end

-- ===========================================================================
-- Setup the players involved in the view.
-- ===========================================================================
function SetupPlayers()

  -- Set up some globals for easy access

  -- Store the local player.  Note, we do this every time we are shown, the local player can change, so don't do it in the one time constructor.
  ms_LocalPlayerID = Game.GetLocalPlayer();

  if (ms_LocalPlayerID == -1) then
    ms_LocalPlayerID = Game.GetLocalObserver();
    if (ms_LocalPlayerID == -1) then
      ms_LocalPlayer = nil
      return false;
    end
    if (ms_LocalPlayerID == PlayerTypes.OBSERVER) then
      ms_LocalPlayerID = 0;
            ms_LocalPlayerLeaderID = -1;
    end
    else
        ms_LocalPlayerLeaderID = PlayerConfigurations[ms_LocalPlayerID]:GetLeaderTypeID();
  end

  ms_LocalPlayer = Players[ms_LocalPlayerID];

  if (ms_OtherPlayerID ~= -1) then
    ms_OtherPlayer = Players[ms_OtherPlayerID];
    local sessionID = DiplomacyManager.FindOpenSessionID(ms_LocalPlayerID, ms_OtherPlayer:GetID());
    if (sessionID ~= nil) then
      local sessionInfo = DiplomacyManager.GetSessionInfo(sessionID);
      ms_InitiatedByPlayerID = sessionInfo.FromPlayer;
    end
  else
    ms_OtherPlayer = nil;
    ms_InitiatedByPlayerID = ms_LocalPlayerID;
  end

  -- Did the AI start this or the human?
  if (ms_InitiatedByPlayerID == ms_OtherPlayerID) then
--		Controls.RefuseDeal:LocalizeAndSetText("LOC_DIPLOMACY_DEAL_REFUSE_DEAL");
    ms_LastIncomingDealProposalAction = DealProposalAction.PROPOSED;
  else
--		Controls.RefuseDeal:LocalizeAndSetText("LOC_DIPLOMACY_DEAL_EXIT_DEAL");
    ms_LastIncomingDealProposalAction = DealProposalAction.PENDING;
  end

  return true;
end

-- ===========================================================================
-- Show a specific leader.
-- This is asynchronous, and event will be sent when the leader has finished loading
-- ===========================================================================
function ShowLeader(player : table )
  local leaderName = PlayerConfigurations[ player:GetID() ]:GetLeaderTypeName();
  if (leaderName ~= ms_showingLeaderName) then
    ms_showingLeaderName = leaderName;
    ms_LastDealResponseAnimation = nil;
    ms_bLeaderShowRequested = true;
    Events.ShowLeaderScreen(leaderName);
    -- TODO: unhide after we know there is a valid image -KS
    Controls.FallbackLeaderImage:SetHide(true); -- Hide until we are loaded
    Controls.LeaderAlpha:SetToBeginning();
    Controls.LeaderAlpha:Play();
  else
    if (not ms_bLeaderShowRequested) then
      -- Already showing the leader, just call the completion callback directly.
      -- We need to do this because we may want to change the animation for
      -- cases where we have two different civs using the same leader.
      LeaderSupport_ClearInitialAnimationState();
      OnLeaderLoaded();
    end
  end
end

-- ===========================================================================
function InitializeView()
  if (not ms_bIsViewInitialized) then
    Events.LeaderScreenFinishedLoading.Add(	OnLeaderLoaded );
    Events.LeaderAnimationComplete.Add( OnLeaderAnimationComplete );
    LeaderSupport_Initialize();
    -- Attach the control that will show the leader.
    UI.SetLeaderImageControl( Controls.FallbackLeaderImage );
    local w,h = UIManager:GetScreenSizeVal();
    Controls.LeaderAnchor:SetOffsetX(w - (w/4));
    Controls.LeaderAnchor:SetOffsetY(h/2); --make sure this stays screen_height/2 so film gate matches camera from animators
    UI.SetLeaderPosition(Controls.LeaderAnchor:GetScreenOffset());

    LuaEvents.DiplomacyActionView_HideIngameUI();

    ms_bIsViewInitialized = true;
  end
end

-- ===========================================================================
function UninitializeView()

  if (ms_bIsViewInitialized) then
    ContextPtr:SetHide(true);
    LuaEvents.DiplomacyActionView_ShowIngameUI();

    if (LeaderSupport_IsLeaderVisible() or ms_bLeaderShowRequested) then
      Events.HideLeaderScreen();
    end

    ms_LastDealResponseAnimation = nil;
    ms_bLeaderShowRequested = false;
    ms_bIsViewInitialized = false;
    ms_bShowingDeal = false;
    ms_ActiveSessionID = nil;
    ms_currentViewMode = -1;
    m_cinemaMode = false;

    ms_OtherPlayer = nil;
    ms_OtherPlayerID = -1;

    ms_SelectedPlayer = nil;
    ms_SelectedPlayerID	= -1;
    ms_SelectedPlayerLeaderTypeName = nil;

    ms_showingLeaderName = "";
    ms_bLeaderShowRequested = false;

    Controls.LeaderResponse_Alpha:SetToBeginning();
    Controls.ConversationSelection_Alpha:SetToBeginning();
    Controls.LeaderResponse_Slide:SetToBeginning();
    Controls.ConversationSelection_Slide:SetToBeginning();
    Controls.AlphaIn:SetSpeed(2);
    Controls.SlideIn:SetSpeed(2);
    Controls.AlphaIn:SetPauseTime(.4);
    Controls.SlideIn:SetPauseTime(.4);
    Controls.SlideIn:SetBeginVal(-200,0);
  end
end

-- ===========================================================================
--	Handle a request to be shown, this should only be called by
--  the diplomacy statement handler.
-- ===========================================================================

function OnOpenDiplomacyActionView(otherPlayerID)

  if (HasCapability("CAPABILITY_DIPLOMACY") or (otherPlayerID == Game.GetLocalPlayer() and HasCapability("CAPABILITY_DIPLOMACY_VIEW_SELF"))) then

    if (otherPlayerID ~= nil) then
      ms_OtherPlayerID = otherPlayerID;
      ms_SelectedPlayerID = otherPlayerID;
    else
      ms_OtherPlayerID = -1;
      ms_SelectedPlayerID = -1;
    end
    InitializeView();
    m_firstOpened = true;

    if (SetupPlayers()) then

      PopulateDiplomacyRibbon(ms_DiplomacyRibbon);

      if (ms_OtherPlayer ~= nil) then
        SelectPlayer(ms_OtherPlayer:GetID(), OVERVIEW_MODE);
      else
        SelectPlayer(ms_LocalPlayer:GetID(), OVERVIEW_MODE);
      end

      if(ms_OtherPlayerID ~= 0) then
        ScrollToNode(ms_OtherPlayerID);
      else
        ms_DiplomacyRibbon.LeaderRibbonScroll:SetScrollValue(0);
      end
    end
  end

end

-- ===========================================================================
function OnLeaderAnimationComplete(animationName : string)

  -- Getting this a little late?
  if (not ms_bIsViewInitialized) then
    return;
  end

  LeaderSupport_UpdateAnimationQueue();
  for _, voiceoverAnimationName in ipairs(VOICEOVER_SUPPORT) do
    if (voiceoverAnimationName == animationName) then
      StartFadeOut();
      break;
    end
  end
end

-- ===========================================================================
function OnSetDealAnimation(animationName : string, useMood : boolean)

  if (ms_currentViewMode == DEAL_MODE) then
    if (useMood ~= nil and useMood == true) then
      local ePlayerMood = DiplomacySupport_GetPlayerMood(ms_SelectedPlayer, ms_LocalPlayerID);

      if (ePlayerMood == DiplomacyMoodTypes.HAPPY) then
        animationName = "HAPPY_" .. animationName;
      elseif (ePlayerMood == DiplomacyMoodTypes.NEUTRAL) then
        animationName = "NEUTRAL_" .. animationName;
      elseif (ePlayerMood == DiplomacyMoodTypes.UNHAPPY) then
        animationName = "UNHAPPY_" .. animationName;
      end
    end
    LeaderSupport_QueueAnimationSequence( ms_SelectedPlayerLeaderTypeName, animationName );
  end
end

-- ===========================================================================

function ShowCinemaMode()
  local w,h = UIManager:GetScreenSizeVal();
  Controls.ConversationContainer:SetHide(m_cinemaMode);

  if (not Controls.BlackFadeAnim:IsReversing()) then
    -- If we faded to black, then we can 'pop' the next animation.
    LeaderSupport_ClearInitialAnimationState();
  end
  -- Set the special display of the LeaderScene.
  Controls.LeaderAnchor:SetOffsetX(w - (w/2.5));
  UI.SetLeaderPosition(Controls.LeaderAnchor:GetScreenOffset());
  local ePlayerMood = DiplomacySupport_GetPlayerMood(ms_SelectedPlayer, ms_LocalPlayerID);
  LeaderSupport_QueueAnimationSequence( ms_OtherLeaderName, m_currentLeaderAnim, ePlayerMood );
  LeaderSupport_QueueSceneEffect( m_currentSceneEffect );
  LuaEvents.DiploScene_CinemaSequence(ms_SelectedPlayerID);
  Controls.OverviewContainer:SetHide(true);
  Controls.VoiceoverTextContainer:SetHide(false);
  Controls.VoiceoverText:SetText(m_voiceoverText);
  Controls.VoiceoverText:ReprocessAnchoring();
  Controls.VoiceoverGrid:ReprocessAnchoring();
  Controls.VoiceoverText_Alpha:SetToBeginning();
  Controls.VoiceoverText_Alpha:Play();
  Controls.VoiceoverText_Slide:SetToBeginning();
  Controls.VoiceoverText_Slide:Play();
end
-- ===========================================================================
function ToggleCinemaMode()
  if (m_bCloseSessionOnFadeComplete == true) then
    -- We are fading to close
    m_bCloseSessionOnFadeComplete = false;
    m_cinemaMode = false;
    DiplomacyManager.CloseSession( ms_ActiveSessionID );
  else
    m_cinemaMode = not m_cinemaMode;
    local w,h = UIManager:GetScreenSizeVal();
    Controls.ConversationContainer:SetHide(m_cinemaMode);

    if (not Controls.BlackFadeAnim:IsReversing()) then
      -- If we faded to black, then we can 'pop' the next animation.
      LeaderSupport_ClearInitialAnimationState();
    end

    -- If we are switching INTO Cinema Mode, send up the appropriate event for the Parallax movement and show the subtitles
    if (m_cinemaMode) then
      ShowCinemaMode();
    -- If we are OUT OF CinemaMode to normal mode, set the idle animations appropriately
    else
      Controls.LeaderAnchor:SetOffsetX(w - (w/3));
      UI.SetLeaderPosition(Controls.LeaderAnchor:GetScreenOffset());
      SelectPlayer(ms_OtherPlayerID, CONVERSATION_MODE, false, true);
      Controls.VoiceoverTextContainer:SetHide(true);
      local ePlayerMood = DiplomacySupport_GetPlayerMood(ms_SelectedPlayer, ms_LocalPlayerID);
      -- What do they think of us?
      if (ePlayerMood == DiplomacyMoodTypes.HAPPY) then
        LeaderSupport_QueueAnimationSequence( ms_SelectedPlayerLeaderTypeName, "HAPPY_IDLE" );
      elseif (ePlayerMood == DiplomacyMoodTypes.NEUTRAL) then
        LeaderSupport_QueueAnimationSequence( ms_SelectedPlayerLeaderTypeName, "NEUTRAL_IDLE" );
      elseif (ePlayerMood == DiplomacyMoodTypes.UNHAPPY) then
        LeaderSupport_QueueAnimationSequence( ms_SelectedPlayerLeaderTypeName, "UNHAPPY_IDLE" );
      end
    end
    Controls.BlackFadeAnim:Reverse();
  end
end
Controls.FadeTimerAnim:RegisterEndCallback(ToggleCinemaMode);

-- ===========================================================================
function OnBlackFadeEnd()
  if (Controls.BlackFadeAnim:GetAlpha() == 0) then
    -- If the alpha is 0 at the end of the fade, hide the control!
    Controls.BlackFade:SetHide(true);
  end
end
Controls.BlackFadeAnim:RegisterEndCallback(OnBlackFadeEnd);

-- ===========================================================================
function OnLeaderLoaded()
  ms_bLeaderShowRequested = false;

  -- Getting this a little late?
  if (not ms_bIsViewInitialized) then
    return;
  end

  LeaderSupport_OnLeaderLoaded();
    local bDoAudio = false;

  -- The leader has loaded, show the screen
  if (ContextPtr:IsHidden()) then
    ContextPtr:SetHide(false);
        bDoAudio = true;
        m_lastLeaderPlayedMusicFor = -1;
  end
  Controls.FallbackLeaderImage:SetHide(false);

  if (ms_ActiveSessionID == nil) then
        bDoAudio = true;
    local ePlayerMood = DiplomacySupport_GetPlayerMood(ms_SelectedPlayer, ms_LocalPlayerID);
    -- What do they think of us?
    if (ePlayerMood == DiplomacyMoodTypes.HAPPY) then
      LeaderSupport_QueueAnimationSequence( ms_SelectedPlayerLeaderTypeName, "HAPPY_IDLE" );
    elseif (ePlayerMood == DiplomacyMoodTypes.NEUTRAL) then
      LeaderSupport_QueueAnimationSequence( ms_SelectedPlayerLeaderTypeName, "NEUTRAL_IDLE" );
    elseif (ePlayerMood == DiplomacyMoodTypes.UNHAPPY) then
      LeaderSupport_QueueAnimationSequence( ms_SelectedPlayerLeaderTypeName, "UNHAPPY_IDLE" );
    end
  end

    if (bDoAudio == true) then
    -- if current civ is unknown, give mods a chance to handle it
    if (UI.GetCivilizationSoundSwitchValueByLeader(ms_LocalPlayerLeaderID) == -1) then
      UI.PauseModCivMusic();
    end

    -- if leader IDs don't match
        if (m_lastLeaderPlayedMusicFor ~= ms_OtherLeaderID) then

      -- stop modder civ's leader music if necessary
      if (m_lastLeaderPlayedMusicFor ~= -1) then
        UI.StopModCivLeaderMusic(m_lastLeaderPlayedMusicFor);
      end

      -- and Wwise IDs don't match
      if (UI.GetCivilizationSoundSwitchValueByLeader(m_lastLeaderPlayedMusicFor) ~= UI.GetCivilizationSoundSwitchValueByLeader(ms_OtherLeaderID)) then
        -- if new leader is also a modder civ, take care of that
        UI.SetSoundSwitchValue("LEADER_SCREEN_CIVILIZATION", UI.GetCivilizationSoundSwitchValueByLeader(ms_OtherLeaderID));
        UI.SetSoundSwitchValue("Game_Location", UI.GetNormalEraSoundSwitchValue(ms_OtherID));
        UI.SetSoundStateValue("Game_Views", "Leader_Screen");
        UI.PlaySound("Play_Leader_Music");
        m_lastLeaderPlayedMusicFor = ms_OtherLeaderID;
      end

      -- always restart modder music if the leader IDs don't match
      if (UI.GetCivilizationSoundSwitchValueByLeader(ms_OtherLeaderID) == -1) then
        UI.PlayModCivLeaderMusic(ms_OtherID);
        m_lastLeaderPlayedMusicFor = ms_OtherID;
      end
        end
    end
end

-- ===========================================================================
function GetStatementHandler(statementTypeName : string)
  local handler = StatementHandlers[statementTypeName];
  if (handler == nil) then
    handler = DefaultHandlers;
  end
  return handler;
end

-- ===========================================================================
function OnDiplomacyMakePeace(eActingPlayer :number, eReactingPlayer :number)
  local localPlayer = Game.GetLocalPlayer();
  if(ms_SelectedPlayerID ~= -1
    and (localPlayer == eActingPlayer or localPlayer == eReactingPlayer)
    and (ms_SelectedPlayerID == eActingPlayer or ms_SelectedPlayerID == eReactingPlayer)) then
    -- The local player just made peace with the selected player, refresh the player panel so the options are updated.
      PopulatePlayerPanelHeader(ms_PlayerPanel, ms_SelectedPlayer);
      PopulatePlayerPanel(ms_PlayerPanel, ms_SelectedPlayer);
  end
end

------------------------------------------------------------------------------
function HasNextQueuedSession(sessionID)
  if (ms_ActiveSessionID ~= nil and ms_ActiveSessionID == sessionID and not m_isInHotload) then

    if (ms_InitiatedByPlayerID == ms_OtherPlayerID) then
      -- The other player initiated contact, just exit
      if (DiplomacyManager.HasQueuedSession(ms_LocalPlayerID)) then
        return true;
      end
    end
  end

  return false;
end

------------------------------------------------------------------------------
function OnDiplomacySessionClosed(sessionID)
  -- Getting this a little late?
  if (not ms_bIsViewInitialized) then
    ms_ActiveSessionID = nil;
    return;
  end

  if (ms_ActiveSessionID ~= nil) then
    if ( ms_ActiveSessionID == sessionID and not m_isInHotload) then
      ms_ActiveSessionID = nil;

      if (ms_currentViewMode == DEAL_MODE) then
        LuaEvents.DiploPopup_HideDeal();
        ms_bShowingDeal = false;
      end

      if (ms_InitiatedByPlayerID == ms_OtherPlayerID) then
        -- The other player initiated contact, just exit
        Close();
      else
        -- The local player started the diplo, go back to the overview.
        SelectPlayer(ms_OtherPlayerID, OVERVIEW_MODE);
        PopulateDiplomacyRibbon(ms_DiplomacyRibbon);
      end
    end
  else
    -- Got a session closed, but we are not in a session.  We may want to refresh the overview screen, the closed session could have been the human sending a diplo request to another human
    if (ms_currentViewMode == OVERVIEW_MODE) then
      local sessionInfo = DiplomacyManager.GetSessionInfo(sessionID);
      if (sessionInfo ~= nil) then
        if (sessionInfo.FromPlayer == Game.GetLocalPlayer() or sessionInfo.ToPlayer == Game.GetLocalPlayer()) then
          SelectPlayer(ms_SelectedPlayerID, OVERVIEW_MODE, true);
        end
      end
      PopulateDiplomacyRibbon(ms_DiplomacyRibbon);
    end
  end

  -- Hotload hack
  if m_isInHotload then
    if ms_OtherPlayerID then 
      -- OnTalkToLeader( ms_OtherPlayerID ); 
    end
    m_isInHotload = false;
  end

end

-------------------------------------------------------------------------------
StatementHandlers = {}

function SetDefaultHandlers(forStatement)
  StatementHandlers[forStatement] = {};
  StatementHandlers[forStatement].ExtractStatement = DiplomacySupport_ExtractStatement;
  StatementHandlers[forStatement].ParseStatement = DiplomacySupport_ParseStatement;
  StatementHandlers[forStatement].ParseStatementSelection = DiplomacySupport_ParseStatementSelection;
  StatementHandlers[forStatement].RemoveInvalidSelections = DiplomacySupport_RemoveInvalidSelections;
  StatementHandlers[forStatement].ApplyStatement = ApplyStatement;
  StatementHandlers[forStatement].OnSelectionButtonClicked = OnSelectConversationDiplomacyStatement;
end

SetDefaultHandlers("DEFAULT");
DefaultHandlers = StatementHandlers["DEFAULT"];

-------------------------------------------------------------------------------
function MakeDeal_ApplyStatement(handler : table, statementTypeName : string, statementSubTypeName : string, toPlayer : number, kStatement : table)

  -- Initial statement or the ackknowledgement of the initial statement?
  if ((kStatement.DealAction == DealProposalAction.ADJUSTED and not ms_bShowingDeal) or (statementSubTypeName == "NONE" and (kStatement.ResponseType == DiplomacyResponseTypes.INITIAL or kStatement.ResponseType == DiplomacyResponseTypes.ACKNOWLEDGE or not ms_bShowingDeal))) then

    ApplyStatement(handler, statementTypeName, statementSubTypeName, toPlayer, kStatement);
    -- Need to hide anything on this screen, except the background
    Controls.ConversationContainer:SetHide(true);
    Controls.OverviewContainer:SetHide(true);

    LuaEvents.DiploPopup_ShowMakeDeal(ms_OtherPlayerID);
    ms_bShowingDeal = true;
    UI.PlaySound("UI_Diplomacy_Menu_Change");

  elseif (kStatement.RespondingToDealAction ~= DealProposalAction.EQUALIZE and kStatement.RespondingToDealAction ~= DealProposalAction.INSPECT and (statementSubTypeName == "HUMAN_ACCEPT_DEAL" or statementSubTypeName == "HUMAN_REFUSE_DEAL" or statementSubTypeName == "AI_ACCEPT_DEAL" or statementSubTypeName == "AI_REFUSE_DEAL")) then
    -- Coming back from the deal screen
    LuaEvents.DiploPopup_HideDeal();
    ms_bShowingDeal = false;

    if (ms_ActiveSessionID ~= nil) then
      if (ms_OtherPlayerID ~= -1 and Players[ms_OtherPlayerID]:IsHuman()) then
        -- Close the session, this will handle exiting back to OVERVIEW_MODE
        DiplomacyManager.CloseSession( ms_ActiveSessionID );
      else
        Controls.ConversationContainer:SetHide(false);
        if (ms_currentViewMode ~= CONVERSATION_MODE) then
          SetConversationMode(ms_SelectedPlayer);
        end

        ApplyStatement(handler, statementTypeName, statementSubTypeName, toPlayer, kStatement);
      end
    else
      -- No session for some reason, just go directly back.
      Controls.OverviewContainer:SetHide(false);
      SelectPlayer(ms_OtherPlayerID, OVERVIEW_MODE);
    end
  else
    -- Other actions just update the deal action.  This is especially true from the AI.  The AI will send, ACCEPT, REJECT, etc.
    -- as the automatic evaluation of the deal occurs.

    local eFromPlayerMood = GetStatementMood( kStatement.FromPlayer, kStatement.FromPlayerMood);
    local kParsedStatement = handler.ExtractStatement(handler, statementTypeName, statementSubTypeName, kStatement.FromPlayer, eFromPlayerMood, kStatement.Initiator);

    if (kParsedStatement.LeaderAnimation ~= nil) then
      local bPlay = true;
      -- Was the a response for an EQUALIZE/INSPECT?
      if (kStatement.RespondingToDealAction == DealProposalAction.EQUALIZE or kStatement.RespondingToDealAction == DealProposalAction.INSPECT) then
        -- We don't want to repeat the last animation
        if (ms_LastDealResponseAnimation ~= nil and kParsedStatement.LeaderAnimation == ms_LastDealResponseAnimation) then
          bPlay = false;
        end
      end

      if (bPlay == true) then
        ms_LastDealResponseAnimation = kParsedStatement.LeaderAnimation;
        LeaderSupport_QueueAnimationSequence( ms_SelectedPlayerLeaderTypeName, kParsedStatement.LeaderAnimation );
      end

    end

    local leaderstr = Locale.Lookup( DiplomacyManager.FindTextKey( kParsedStatement.StatementText, kStatement.FromPlayer, kStatement.FromMood, toPlayer));
    LuaEvents.DiploPopup_DealUpdated(ms_OtherPlayerID, kStatement.DealAction, leaderstr);
  end
end

-------------------------------------------------------------------------------
function MakeDeal_TestValid(sessionID, otherPlayer)

  if (sessionID ~= nil) then
    local sessionInfo = DiplomacyManager.GetSessionInfo(sessionID);
    if (sessionInfo.FromPlayer == otherPlayer) then
      local pDeal = DealManager.GetWorkingDeal(DealDirection.INCOMING, Game.GetLocalPlayer(), otherPlayer);
      if (pDeal == nil or pDeal:GetItemCount() == 0 or not pDeal:IsValid()) then
        -- Invalid session
        return false;
      end
    end
  end
  return true;

end

SetDefaultHandlers("MAKE_DEAL");
StatementHandlers["MAKE_DEAL"].ApplyStatement = MakeDeal_ApplyStatement;
StatementHandlers["MAKE_DEAL"].TestValid = MakeDeal_TestValid;


-------------------------------------------------------------------------------
function MakeDemand_ApplyStatement(handler : table, statementTypeName : string, statementSubTypeName : string, toPlayer : number, kStatement : table)

  ms_currentViewMode = DEAL_MODE;

  if (statementSubTypeName == "NONE" and (kStatement.ResponseType == DiplomacyResponseTypes.INITIAL or kStatement.ResponseType == DiplomacyResponseTypes.ACKNOWLEDGE or not ms_bShowingDeal)) then

    ApplyStatement(handler, statementTypeName, statementSubTypeName, toPlayer, kStatement);

    -- Need to hide anything on this screen, except the background
    Controls.ConversationContainer:SetHide(true);
    Controls.OverviewContainer:SetHide(true);

    LuaEvents.DiploPopup_ShowMakeDemand(ms_OtherPlayerID);
    ms_bShowingDeal = true;
    UI.PlaySound("UI_Diplomacy_Menu_Change");
  elseif (statementSubTypeName == "HUMAN_ACCEPT_DEAL" or statementSubTypeName == "HUMAN_REFUSE_DEAL" or statementSubTypeName == "AI_ACCEPT_DEAL" or statementSubTypeName == "AI_REFUSE_DEAL") then

    LuaEvents.DiploPopup_HideDeal();
    ms_bShowingDeal = false;

    if (ms_ActiveSessionID ~= nil) then
      if (ms_OtherPlayerID ~= -1 and Players[ms_OtherPlayerID]:IsHuman()) then
        -- Close the session, this will handle exiting back to OVERVIEW_MODE
        DiplomacyManager.CloseSession( ms_ActiveSessionID );
      else
        Controls.ConversationContainer:SetHide(false);
        if (ms_currentViewMode ~= CONVERSATION_MODE) then
          SetConversationMode(ms_SelectedPlayer);
        end

        ApplyStatement(handler, statementTypeName, statementSubTypeName, toPlayer, kStatement);
      end
    else
      -- No session for some reason, just go directly back.
      Controls.OverviewContainer:SetHide(false);
      SelectPlayer(ms_OtherPlayerID, OVERVIEW_MODE);
    end
  end
end

SetDefaultHandlers("MAKE_DEMAND");
StatementHandlers["MAKE_DEMAND"].ApplyStatement = MakeDemand_ApplyStatement;

-- ===========================================================================
function OnTalkToLeader( playerID : number )
  OnOpenDiplomacyActionView( playerID );
end

-- ===========================================================================
function HandleESC()
  if (ms_currentViewMode == CONVERSATION_MODE) then
    if (ms_ActiveSessionID ~= nil) then
      if (Controls.BlackFadeAnim:IsStopped()) then
        ExitConversationMode();
      end
    else
      Close();
    end
  elseif (ms_currentViewMode == CINEMA_MODE) then
    UI.PlaySound("Stop_Leader_Speech");
    if (Controls.BlackFadeAnim:IsStopped()) then
      StartFadeOut();
    end
  elseif (ms_currentViewMode == DEAL_MODE) then
      -- No handling ESC while transitioning to/from deal mode.  The deal screen will handle it if it is up.
  else
    if(m_PopupDialog:IsOpen())then
      m_PopupDialog:Close()
    else
    Close();
    end
  end
end


-- ===========================================================================
--	INPUT Handling
--	If this context is visible, it will get a crack at the input.
-- ===========================================================================
function KeyHandler( key:number )
  if (key == Keys.VK_ESCAPE) then HandleESC(); return true; end
  return false;
end

-- ===========================================================================
function OnInputHandler( pInputStruct:table )
  local uiMsg = pInputStruct:GetMessageType();
  if uiMsg == KeyEvents.KeyUp then
    return KeyHandler( pInputStruct:GetKey() );
  end
  if (uiMsg == MouseEvents.LButtonUp or
    uiMsg == MouseEvents.RButtonUp or
    uiMsg == MouseEvents.MButtonUp or
    uiMsg == MouseEvents.PointerUp) then
    ClearValueEdit();
  end

  return false;
end

-- ===========================================================================
function OnDiplomacyStatement(fromPlayer : number, toPlayer : number, kVariants : table)

  local localPlayer = Game.GetLocalPlayer();

  if (toPlayer == localPlayer or fromPlayer == localPlayer) then

    -- No diplomacy active?  We shouldn't be getting statements if so, but if we do, ignore it.
    if (not HasCapability("CAPABILITY_DIPLOMACY")) then
      DiplomacyManager.CloseSession( kVariants.SessionID );
      return;
    end

    local statementTypeName = DiplomacyManager.GetKeyName( kVariants.StatementType );
    if (statementTypeName ~= nil) then
      local statementSubTypeName = DiplomacyManager.GetKeyName( kVariants.StatementSubType );

      local handler = GetStatementHandler(statementTypeName);

      if (ms_ActiveSessionID == nil) then

        ms_ActiveSessionID = kVariants.SessionID;

        if (toPlayer == localPlayer) then
          ms_OtherPlayerID = fromPlayer;
        else
          ms_OtherPlayerID = toPlayer;
        end

        local pOtherPlayerConfig = PlayerConfigurations[ ms_OtherPlayerID ];

        ms_OtherLeaderName = pOtherPlayerConfig:GetLeaderTypeName();
        ms_OtherCivilizationID = pOtherPlayerConfig:GetCivilizationTypeID();
        ms_OtherLeaderID = pOtherPlayerConfig:GetLeaderTypeID();

        -- Check to see if the session is valid.
        if (handler.TestValid == nil or handler.TestValid(ms_ActiveSessionID, ms_OtherPlayerID)) then
          InitializeView();
          SetupPlayers();
          PopulateDiplomacyRibbon(ms_DiplomacyRibbon);
        else
          -- Clear the session ID, and close it.
          local sessionID = ms_ActiveSessionID;
          ms_ActiveSessionID = nil;
          DiplomacyManager.CloseSession( sessionID );
          return;
        end
      end

      if (statementTypeName == "MAKE_DEAL") then
        -- Select (or reselect) the player.  This will do nothing if the player is already selected in the desired mode.
        SelectPlayer(ms_OtherPlayerID, DEAL_MODE);
      else
        local viewMode = CONVERSATION_MODE;
        if UI.IsPlayersLeaderAnimated(ms_OtherPlayerID) then
          --If this is a voiced-over animation, then set the voiceover text and SWITCH TO CINEMA MODE
          local eFromPlayerMood = GetStatementMood(kVariants.FromPlayer, kVariants.FromPlayerMood);
          local kParsedStatement = handler.ExtractStatement(handler, statementTypeName, statementSubTypeName, kVariants.FromPlayer, eFromPlayerMood, kVariants.Initiator);
          for _, voiceoverAnimationName in ipairs(VOICEOVER_SUPPORT) do
            if (voiceoverAnimationName == kParsedStatement.LeaderAnimation ) then
              viewMode = CINEMA_MODE;
              break;
            end
          end
        end

        -- Select (or reselect) the player.  This will do nothing if the player is already selected in the desired mode.
        -- Also, we are allowing selecting dead players so that defeat sessions will work.
        SelectPlayer(ms_OtherPlayerID, viewMode, false, true);
      end

      if (handler.ApplyStatement ~= nil) then
        handler.ApplyStatement(handler, statementTypeName, statementSubTypeName, toPlayer, kVariants);
        m_isInHotload = false;	-- If this far (and was hotloading) nothing left to hotload.
      end
    end
  end
end

-- ===========================================================================
function ResetPlayerPanel()
  -- Reset the state of the nested menus
  if (ms_PlayerPanel ~= nil) then
    ms_PlayerPanel.ContentStack:CalculateSize();
    ms_PlayerPanel.ContentStack:ReprocessAnchoring();
    ms_PlayerPanel.ContentStack:SetHide(false);
    ms_PlayerPanel.SubOptionsStack:SetHide(true);
  end
end

-- ===========================================================================
function Close()
  UninitializeView();
  LuaEvents.DiploScene_SceneClosed();

  ResetPlayerPanel();

  local localPlayer = Game.GetLocalPlayer();
  UI.SetSoundSwitchValue("Game_Location", UI.GetNormalEraSoundSwitchValue(ms_LocalPlayer:GetID()));

    -- always Stop_Leader_Music to resume the game music properly...
    UI.PlaySound("Stop_Leader_Music");

    -- check if we need to also stop modder civ music
    if (UI.GetCivilizationSoundSwitchValueByLeader(m_lastLeaderPlayedMusicFor) == -1) then
    UI.StopModCivLeaderMusic(m_lastLeaderPlayedMusicFor);
    end

    -- if it's not an observer game...
    if (ms_LocalPlayerLeaderID ~= -1) then
        -- and the local player is not a known Wwise leader...
        if (UI.GetCivilizationSoundSwitchValueByLeader(ms_LocalPlayerLeaderID) == -1) then
            -- resume modder music, instead of Roland's
            UI.ResumeModCivMusic();
        end
  end

    UI.PlaySound("Exit_Leader_Screen");
    UI.SetSoundStateValue("Game_Views", "Normal_View");
end


-- ===========================================================================
--	Close Button Handler
--	Continue out of diplomacy view.
-- ===========================================================================
function OnClose()
  -- Act like they pressed ESC so we clean up correctly
  HandleESC();
end

-- ===========================================================================
function OnShow()
  -- NOTE: We can get here after the OnDiplomacyStatement handler has done some setup, so don't reset too much, assume that OnHide has closed things down properly.

  Controls.AlphaIn:SetToBeginning();
  Controls.SlideIn:SetToBeginning();
  Controls.AlphaIn:Play();
  Controls.SlideIn:Play();

  m_bCloseSessionOnFadeComplete = false;

  ms_IconAndTextIM:ResetInstances();

  SetupPlayers();
  UpdateSelectedPlayer(true);

  LuaEvents.DiploBasePopup_HideUI(true);
  LuaEvents.DiploScene_SceneOpened(ms_SelectedPlayerID);			-- Signal the LeaderScene background system that the scene should be shown
  TTManager:ClearCurrent();	-- Clear any tool tips raised;

  if (m_cinemaMode) then
    ShowCinemaMode();
    StartFadeIn();
  end

end

----------------------------------------------------------------
function OnHide()

  LuaEvents.DiploBasePopup_HideUI(false);
  Controls.BlackFade:SetHide(true);
  Controls.BlackFadeAnim:SetToBeginning();
  -- Game Core Events
  Events.LeaderAnimationComplete.Remove( OnLeaderAnimationComplete );
  Events.LeaderScreenFinishedLoading.Remove( OnLeaderLoaded );

  ms_showingLeaderName = "";

end

-- ===========================================================================
function SetButtonSelected( buttonControl: table, isSelected : boolean )
  buttonControl:SetSelected(isSelected);
  local textColor = COLOR_BUTTONTEXT_NORMAL;
  local shadowColor = COLOR_BUTTONTEXT_NORMAL_SHADOW;
  if (isSelected == true) then
    textColor = COLOR_BUTTONTEXT_SELECTED;
    shadowColor = COLOR_BUTTONTEXT_SELECTED_SHADOW;
  end
  buttonControl:GetTextControl():SetColor(textColor,0);
  buttonControl:GetTextControl():SetColor(shadowColor,1);
end

-- ===========================================================================
function OnLocalPlayerTurnEnd()
  if (not ContextPtr:IsHidden()) then
    -- If the local player's turn ends (turn timer usually), act like they hit esc.
    if (ms_currentViewMode == DEAL_MODE) then
      -- Unless we were in the deal mode, then just close, the deal view will close too.
      Close();
    else
      HandleESC();
    end
  end
end


-- ===========================================================================
--	Engine Event
-- ===========================================================================
function OnUserRequestClose()
  -- Is this showing; if so then it needs to raise dialog to handle close
  if ContextPtr:IsHidden()==false then
    if Controls.QuitPopupDialog:IsHidden() then
      Controls.QuitPopupDialog:SetHide( false );
    end
  end
end

-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnQuitYes()
  Events.UserConfirmedClose();
end

-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnQuitNo()
  Controls.QuitPopupDialog:SetHide( true );
end

-- ===========================================================================
--	HOTLOADING UI EVENTS
-- ===========================================================================
function OnInit(isHotload:boolean)
  CreatePanels();
  if isHotload and not ContextPtr:IsHidden() then
    LuaEvents.GameDebug_GetValues( "DiplomacyActionView" );
    InitializeView();
    OnShow();
  end
end

--	Context DESTRUCTOR - Not called when screen is dismissed, only if the whole context is removed!
function OnShutdown()
  -- Cache values for hotloading...
  LuaEvents.GameDebug_AddValue("DiplomacyActionView", "isHidden", ContextPtr:IsHidden());
end

-- LUA EVENT:  Set cached values back after a hotload.
function OnGameDebugReturn( context:string, contextTable:table )
  if context == "DiplomacyActionView" and contextTable["isHidden"] ~= nil and not contextTable["isHidden"] then
    CreatePanels();
  end
end

-- ===========================================================================
function OnGamePauseStateChanged(bNewState)
  if (not ContextPtr:IsHidden()) then
    ResetPlayerPanel();
    SelectPlayer(ms_SelectedPlayerID, OVERVIEW_MODE, true);
  end
end

-- ===========================================================================
function Initialize()

  ContextPtr:SetInitHandler( OnInit );
  ContextPtr:SetInputHandler( OnInputHandler, true );
  ContextPtr:SetShutdown( OnShutdown );
  ContextPtr:SetShowHandler( OnShow );
  ContextPtr:SetHideHandler( OnHide );
  LuaEvents.GameDebug_Return.Add(OnGameDebugReturn);

  -- Game Core Events
  Events.DiplomacySessionClosed.Add( OnDiplomacySessionClosed );
  Events.DiplomacyStatement.Add( OnDiplomacyStatement );
  Events.DiplomacyMakePeace.Add( OnDiplomacyMakePeace );
  Events.LocalPlayerTurnEnd.Add( OnLocalPlayerTurnEnd );
  Events.UserRequestClose.Add( OnUserRequestClose );
  Events.GamePauseStateChanged.Add(OnGamePauseStateChanged);

  -- LUA Events
  LuaEvents.CityBannerManager_TalkToLeader.Add(OnTalkToLeader);
  LuaEvents.DiploPopup_TalkToLeader.Add(OnTalkToLeader);
  LuaEvents.DiplomacyRibbon_OpenDiplomacyActionView.Add(OnOpenDiplomacyActionView);
  LuaEvents.TopPanel_OpenDiplomacyActionView.Add(OnOpenDiplomacyActionView);
  LuaEvents.DiploScene_SetDealAnimation.Add(OnSetDealAnimation);

  --LuaEvents.Tutorial_ViewDiploIntel.Add(OnActivateIntelRelationshipPanel(Controls.PlayerContainer));
  --LuaEvents.Tutorial_ViewDiploAccessLevel.Add(OnActivateIntelAccessLevelPanel(Controls.PlayerContainer));
  --LuaEvents.Tutorial_ViewDiploRelationship.Add(OnActivateIntelGossipHistoryPanel(Controls.PlayerContainer));
  --LuaEvents.Tutorial_CloseDiploActionView.Add(Close);

  Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose );
  Controls.CloseButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
  Controls.YesButton:RegisterCallback( Mouse.eLClick, OnQuitYes );
  Controls.NoButton:RegisterCallback( Mouse.eLClick, OnQuitNo );

  -- Size controls for screen:
  local screenX, screenY:number = UIManager:GetScreenSizeVal();
  local leaderResponseX = math.floor(screenX * CONVO_X_MULTIPLIER);
  Controls.LeaderResponseGrid:SetSizeX(leaderResponseX);
  Controls.LeaderResponseText:SetWrapWidth(leaderResponseX-40);
end
Initialize();
