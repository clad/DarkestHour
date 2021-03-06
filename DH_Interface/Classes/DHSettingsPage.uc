//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DHSettingsPage extends UT2K4SettingsPage;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
        local rotator PlayerRot;
        local int i;

        super.InitComponent(MyController, MyOwner);
        PageCaption = t_Header.Caption;

        GetSizingButton();

        PlayerRot = PlayerOwner().Rotation;
        SavedPitch = PlayerRot.Pitch;
        PlayerRot.Pitch = 0;
        PlayerRot.Roll = 0;
        PlayerOwner().SetRotation(PlayerRot);

    for (i = 0; i < PanelCaption.Length && i < PanelClass.Length && i < PanelHint.Length; ++i)
    {
        Profile("Settings_" $ PanelCaption[i]);
        c_Tabs.AddTab(PanelCaption[i], PanelClass[i],, PanelHint[i]);
        Profile("Settings_" $ PanelCaption[i]);
    }
        tp_Game = UT2K4Tab_GameSettings(c_Tabs.BorrowPanel(PanelCaption[3]));
}

function GetSizingButton()
{
        local int i;
        SizingButton = none;
        for (i = 0; i < Components.Length; ++i)
        {
                if (GUIButton(Components[i]) == none)
                        continue;

                if (SizingButton == none || Len(GUIButton(Components[i]).Caption) > Len(SizingButton.Caption))
                        SizingButton = GUIButton(Components[i]);
        }
}

function bool InternalOnPreDraw(Canvas Canvas)
{
        local int X, i;
        local float XL,YL;

        if (SizingButton == none)
                return false;

        SizingButton.Style.TextSize(Canvas, SizingButton.MenuState, SizingButton.Caption, XL, YL, SizingButton.FontScale);

        XL += 32;
        X = Canvas.ClipX - XL;
        for (i = Components.Length - 1; i >= 0; i--)
        {
            if (GUIButton(Components[i]) == none)
                        continue;
                    Components[i].WinWidth = XL;
                    Components[i].WinLeft = X;
                    X -= XL;
        }
        return false;
}

function bool InternalOnCanClose(optional bool bCanceled)
{
    return true;
}

function InternalOnClose(optional bool bCanceled)
{
    local rotator NewRot;

    NewRot = PlayerOwner().Rotation;
    NewRot.Pitch = SavedPitch;
    PlayerOwner().SetRotation(NewRot);

    super.OnClose(bCanceled);
}

function InternalOnChange(GUIComponent Sender)
{
    super.InternalOnChange(Sender);

    if (c_Tabs.ActiveTab == none)
        ActivePanel = none;
    else ActivePanel = Settings_Tabs(c_Tabs.ActiveTab.MyPanel);
}

function BackButtonClicked()
{
    if (InternalOnCanClose(false))
    {
        SaveConfig();

        c_Tabs.ActiveTab.OnDeActivate();

        Controller.CloseMenu(false);
    }
}

function DefaultsButtonClicked()
{
    ActivePanel.ResetClicked();
}

function bool ButtonClicked(GUIComponent Sender)
{
        ActivePanel.AcceptClicked();
        return true;
}

event bool NotifyLevelChange()
{
    bPersistent = false;
    LevelChanged();
    return true;
}

defaultproperties
{
    Begin Object Class=DHGUITabControl Name=SettingTabs
        bFillSpace=false
        bDockPanels=true
        TabHeight=0.06
        BackgroundStyleName="DHHeader"
        WinHeight=0.044
        RenderWeight=0.49
        TabOrder=3
        bAcceptsInput=true
        OnActivate=SettingTabs.InternalOnActivate
        OnChange=DHSettingsPage.InternalOnChange
    End Object
    c_Tabs=DHGUITabControl'DH_Interface.DHSettingsPage.SettingTabs'
    Begin Object Class=DHGUIHeader Name=SettingHeader
        Caption="Settings"
        StyleName="DHTopper"
        WinHeight=32.0
        RenderWeight=0.3
    End Object
    t_Header=DHGUIHeader'DH_Interface.DHSettingsPage.SettingHeader'
    Begin Object Class=DHSettings_Footer Name=SettingFooter
        Spacer=0.01
        StyleName="DHFooter"
        WinTop=0.95
        WinHeight=0.045
        RenderWeight=0.3
        TabOrder=4
        OnPreDraw=SettingFooter.InternalOnPreDraw
    End Object
    t_Footer=DHSettings_Footer'DH_Interface.DHSettingsPage.SettingFooter'
    PanelClass(0)="DH_Interface.DHTab_GameSettings"
    PanelClass(1)="DH_Interface.DHTab_DetailSettings"
    PanelClass(2)="DH_Interface.DHTab_AudioSettings"
    PanelClass(3)="DH_Interface.DHTab_Controls"
    PanelClass(4)="DH_Interface.DHTab_Input"
    PanelClass(5)="DH_Interface.DHTab_Hud"
    PanelClass(6)="none"
    PanelCaption(0)="Game"
    PanelCaption(1)="Display"
    PanelCaption(2)="Audio"
    PanelCaption(3)="Controls"
    PanelCaption(5)="Hud"
    PanelCaption(6)="none"
    PanelHint(0)="Configure your Darkest Hour game..."
    PanelHint(1)="Select your resolution or change your display and detail settings..."
    PanelHint(2)="Adjust your audio experience..."
    PanelHint(3)="Configure your keyboard controls..."
    PanelHint(5)="Customize your HUD..."
    PanelHint(6)="how did you get this?"
    Background=texture'DH_GUI_Tex.Menu.Setupmenu'
}
