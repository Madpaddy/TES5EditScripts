{
  CCOR Compatibility Script v0.5
  Created by matortheeternal
  
  Applies CCOR global variable conditions to COBJ recipes in the 
  selected mods.  
}

unit UserScript;

const
  vs = 'v0.5';
  bethesdaFiles = 'Skyrim.esm'#13'Update.esm'#13'Dawnguard.esm'#13'Dragonborn.esm'#13'Hearthfires.esm'
  #13'Skyrim.Hardcoded.keep.this.with.the.exe.and.otherwise.ignore.it.I.really.mean.it.dat';
  ccofn = 'Complete Crafting Overhaul_Remade.esp';
  separatepatch = false; // set to true to generate a separate patch file

var
  slFiles, slGlobals: TStringList;
  patchedfiles: integer;
  
//=========================================================================
// has keyword
function HasKeyword(rec: IInterface; kw: string): boolean;
var
  kwda: IInterface;
  n: integer;
begin
  Result := false;
  kwda := ElementByPath(rec, 'KWDA');
  for n := 0 to ElementCount(kwda) - 1 do
    if GetElementEditValues(LinksTo(ElementByIndex(kwda, n)), 'EDID') = kw then 
      Result := true;
end;

//=========================================================================
// add learning global value condition
procedure algvc(c: IInterface; gv: string);
var
  condition: IInterface;
  index1, index2: integer;
begin
  // first condition
  index1 := slGlobals.IndexOf('CCO_LearningEnabled');
  if index1 = -1 then begin
    AddMessage('Couldn''t find CCO_LearningEnabled');
    exit;
  end;
  condition := ElementAssign(c, HighInteger, nil, False);
  SetElementEditValues(condition, 'CTDA - \Type', '10010000'); // Equal to / Or
  SetElementNativeValues(condition, 'CTDA - \Comparison Value', '0.0');
  SetElementEditValues(condition, 'CTDA - \Function', 'GetGlobalValue');
  SetElementNativeValues(condition, 'CTDA - \Global', slGlobals.Objects[index1]);
  
  // second condition
  index1 := slGlobals.IndexOf('CCO_LearningRequiredtoSmith');
  if index1 = -1 then begin
    AddMessage('Couldn''t find CCO_LearningRequiredtoSmith');
    exit;
  end;
  index2 := slGlobals.IndexOf(gv);
  if index2 = -1 then begin
    AddMessage('Couldn''t find '+gv);
    exit;
  end;
  condition := ElementAssign(c, HighInteger, nil, False);
  SetElementEditValues(condition, 'CTDA - \Type', '11000100'); // Greater than or equal to / Use global
  SetElementNativeValues(condition, 'CTDA - \Comparison Value', slGlobals.Objects[index1]);
  SetElementEditValues(condition, 'CTDA - \Function', 'GetGlobalValue');
  SetElementNativeValues(condition, 'CTDA - \Global', slGlobals.Objects[index2]);
end;
  
//=========================================================================
// add global value condition
procedure agvc(c: IInterface; gv: string);
var
  condition: IInterface;
  index: integer;
begin
  index := slGlobals.IndexOf(gv);
  if index = -1 then begin
    AddMessage('Couldn''t find '+gv);
    exit;
  end;
  condition := ElementAssign(c, HighInteger, nil, False);
  SetElementEditValues(condition, 'CTDA - \Type', '10000000'); // equal to
  SetElementEditValues(condition, 'CTDA - \Comparison Value', '1.0');
  SetElementEditValues(condition, 'CTDA - \Function', 'GetGlobalValue');
  SetElementNativeValues(condition, 'CTDA - \Global', slGlobals.Objects[index]);
  While CanMoveUp(condition) do
    MoveUp(condition);
end;
  
//=========================================================================
// CCO mod supported condition
procedure cmcs(c: IInterface);
var
  condition: IInterface;
  index: integer;
begin
  index := slGlobals.IndexOf('CCO_MODSupported');
  if index = -1 then begin
    AddMessage('Couldn''t find CCO_MODSupported');
    exit;
  end;
  condition := ElementAssign(c, HighInteger, nil, False);
  SetElementEditValues(condition, 'CTDA - \Type', '10000000'); // equal to
  SetElementEditValues(condition, 'CTDA - \Comparison Value', '1.0');
  SetElementEditValues(condition, 'CTDA - \Function', 'GetGlobalValue');
  SetElementNativeValues(condition, 'CTDA - \Global', slGlobals.Objects[index]);
  While CanMoveUp(condition) do
    MoveUp(condition);
end;

//=========================================================================
// tanning rack conditions
procedure TanningRackConditions(cobj: IInterface; conditions: IInterface);
var
  cnam, items, li, item: IInterface;
  edid, full: string;
begin
  cnam := LinksTo(ElementByPath(cobj, 'CNAM'));
  edid := Lowercase(GetElementEditValues(cnam, 'EDID'));
  full := Lowercase(GetElementEditValues(cnam, 'EDID'));
  if HasKeyword(cnam, '') or (Pos('backpack', edid) > 0) or (Pos('backpack', full) > 0) then
    agvc(conditions, 'CCO_BackpackRecipes');
  // mark as breakdown recipe if requires WEAP or ARMO
  items := ElementByPath(cobj, 'Items');
  for i := 0 to ElementCount(items) - 1 do begin
    li := ElementByIndex(items, i);
    item := LinksTo(ElementByPath(li, 'CNTO - Item\Item'));
    if (Signature(item) = 'WEAP') or (Signature(item) = 'ARMO') then begin
      agvc(conditions, 'CCO_BreakdownRecipes');
      Break;
    end;    
  end;
end;

//=========================================================================
// smithing forge conditions
procedure SmithingForgeConditions(cnam: IInterface; conditions: IInterface);
var
  atype, edid, full: string;
  clothing: boolean;
begin
  edid := Lowercase(GetElementEditValues(cnam, 'EDID'));
  full := Lowercase(GetElementEditValues(cnam, 'FULL'));
  if Signature(cnam) = 'ARMO' then begin
    // armor type condition
    clothing := false;
    atype := GetElementEditValues(cnam, 'BODT\Armor Type');
    if (atype = 'Heavy Armor') or HasKeyword(cnam, 'ArmorHeavy') then begin
      agvc(conditions, 'CCO_ArmorHeavyRecipes');
    end
    else if (atype = 'Light Armor') or HasKeyword(cnam, 'ArmorLight') then begin
      agvc(conditions, 'CCO_ArmorLightRecipes');
    end
    else if (atype = 'Clothing') or HasKeyword(cnam, 'ArmorClothing') then begin
      agvc(conditions, 'CCO_ArmorClothingRecipes');
      clothing := true;
    end;
    // armor piece condition
    if HasKeyword(cnam, 'ArmorBoots') then begin
      if clothing then agvc(conditions, 'CCO_ClothingBootRecipes')
      else agvc(conditions, 'CCO_ArmorBootRecipes');
    end
    else if HasKeyword(cnam, 'ArmorGauntlets') then begin
      if clothing then agvc(conditions, 'CCO_ClothingGloveRecipes')
      else agvc(conditions, 'CCO_ArmorGauntletRecipes');
    end
    else if HasKeyword(cnam, 'ArmorCuirass') then begin
      if clothing then agvc(conditions, 'CCO_ClothingRobeRecipes')
      else agvc(conditions, 'CCO_ArmorCuirassRecipes');
    end
    else if HasKeyword(cnam, 'ArmorHelmet') then begin
      if clothing then agvc(conditions, 'CCO_ClothingHoodRecipes')
      else agvc(conditions, 'CCO_ArmorHelmetRecipes');
    end
    else if HasKeyword(cnam, 'ArmorShield') then 
      agvc(conditions, 'CCO_ArmorShieldRecipes')
    else if HasKeyword(cnam, '') or (Pos('cloak', edid) > 0) or (Pos('cloak', full) > 0) then
      agvc(conditions, 'CCO_ClothingCloakRecipes')
    else if HasKeyword(cnam, 'ClothingCirclet') then 
      agvc(conditions, 'CCO_MiscCircletRecipes');
    // learning condition
    if Pos('draugr', edid) > 0 then
      algvc(conditions, 'CCO_LearningDragur')
    else if Pos('forsworn', edid) > 0 then
      algvc(conditions, 'CCO_LearningForsworn')
    else if Pos('falmer', edid) > 0 then
      algvc(conditions, 'CCO_LearningFalmer');
  end
  else if Signature(cnam) = 'WEAP' then begin
    // weapon type condition
    if HasKeyword(cnam, 'WeapTypeSword') then 
      agvc(conditions, 'CCO_WeapSwordRecipes')
    else if HasKeyword(cnam, 'WeapTypeDagger') then
      agvc(conditions, 'CCO_WeapDaggerRecipes')
    else if HasKeyword(cnam, 'WeapTypeGreatsword') then
      agvc(conditions, 'CCO_WeapGreatswordRecipes')
    else if HasKeyword(cnam, 'WeapTypeWarAxe') then
      agvc(conditions, 'CCO_WeapWarAxeRecipes')
    else if HasKeyword(cnam, 'WeapTypeBattleaxe') then
      agvc(conditions, 'CCO_WeapBattleaxeRecipes')
    else if HasKeyword(cnam, 'WeapTypeBow') then
      agvc(conditions, 'CCO_WeapBowRecipes')
    else if HasKeyword(cnam, 'WeapTypeMace') then
      agvc(conditions, 'CCO_WeapMaceRecipes')
    else if HasKeyword(cnam, 'WeapTypeWarhammer') then
      agvc(conditions, 'CCO_WeapWarhammerRecipes');
    // learning condition
    if HasKeyword(cnam, 'WeapMaterialDraugr') then
      algvc(conditions, 'CCO_LearningDragur')
    else if Pos('forsworn', edid) > 0 then
      algvc(conditions, 'CCO_LearningForsworn')
    else if Pos('falmer', edid) > 0 then
      algvc(conditions, 'CCO_LearningFalmer');
  end
  else if Signature(cnam) = 'AMMO' then begin
    // ammo condition
    agvc(conditions, 'CCO_WeapAmmoRecipes');
  end
  else if Signature(cnam) = 'MISC' then begin
    // jewelry conditions
    if HasKeyword(cnam, 'ClothingRing') then
      agvc(conditions, 'CCO_MiscRingRecipes')
    else if HasKeyword(cnam, 'ClothingNecklace') then
      agvc(conditions, 'CCO_MiscNecklaceRecipes');
  end;
  
  // CCO_MODSupported condition
  // cmcs(conditions);
end;

//=========================================================================
// smithing smelter conditions
procedure SmithingSmelterConditions(cobj: IInterface; conditions: IInterface);
var
  items, li, item: IInterface;
  i: integer;
begin
  items := ElementByPath(cobj, 'Items');
  for i := 0 to ElementCount(items) - 1 do begin
    li := ElementByIndex(items, i);
    item := LinksTo(ElementByPath(li, 'CNTO - Item\Item'));
    if (Signature(item) = 'WEAP') or (Signature(item) = 'ARMO') then begin
      agvc(conditions, 'CCO_BreakdownRecipes');
      Break;
    end;    
  end;
end;
  
//=========================================================================
// initialize script
function Initialize: integer;
begin
  // welcome messages
  AddMessage(#13#10);
  AddMessage('----------------------------------------------------------');
  AddMessage('CCO Global Variable Application Script '+vs);
  AddMessage('----------------------------------------------------------');
  AddMessage('');
  
  // create stringlists
  slFiles := TStringList.Create;
  slGlobals := TStringList.Create;
  
  // process only files
  ScriptProcessElements := [etFile];
end;

//=========================================================================
// load selected files into slFiles stringlist
function Process(f: IInterface): integer;
begin
  if GetFileName(f) = ccofn then 
    exit;
    
  if (Pos(GetFileName(f), bethesdaFiles) > 0) then
    exit;
    
  slFiles.AddObject(GetFileName(f), TObject(f));
end;

//=========================================================================
// add CCO global variables and modify COBJ conditions
function Finalize: integer;
var
  ccoFile, e, ne, cf, cobj, group, conditions, cnam, cc: IInterface;
  i, j: integer;
  edid, bnam: string;
begin
  // find cco file
  for i := 0 to FileCount - 1 do
    if GetFileName(FileByIndex(i)) = ccofn then
      ccoFile := FileByIndex(i);

  // if cco file not found, terminate script
  if not Assigned(ccoFile) then begin
    AddMessage(ccofn+' not found, terminating script.');
    Result := -1;
  end;
  
  { generate patchfile }
  if separatepatch then begin
    Result := -1;
  end;
  
  { modify existing files }
  AddMessage('Making files compatible with CCOR...');
  for i := 0 to slFiles.Count - 1 do begin
    // skip file if no COBJ records present
    cf := ObjectToElement(slFiles.Objects[i]);
    cobj := GroupBySignature(cf, 'COBJ');
    if not Assigned(cobj) then Continue;
    AddMessage('    Patching '+slFiles[i]);
    Inc(patchedfiles);
    
    // add masters if missing
    AddMasterIfMissing(cf, 'Skyrim.esm');
    AddMasterIfMissing(cf, 'Update.esm');
    
    // copy globals from ccoFile
    AddMessage('        Copying globals...');
    group := GroupBySignature(ccoFile, 'GLOB');
    for j := 0 to ElementCount(group) - 1 do begin
      e := ElementByIndex(group, j);
      edid := Lowercase(GetElementEditValues(e, 'EDID'));
      if (Pos('cco_', edid) = 1) and (FormID(e) < 30408704) then begin
        ne := wbCopyElementToFile(e, cf, True, True);
        SetLoadOrderFormID(ne, FormID(e));
        if i = 0 then 
          slGlobals.AddObject(edid, TObject(FormID(e)));
      end;
    end;
    
    // loop through COBJ records and apply conditions
    AddMessage('        Patching COBJ records...');
    for j := 0 to ElementCount(cobj) - 1 do begin
      cc := nil;
      e := ElementByIndex(cobj, j);
      AddMessage('            ... '+Name(e));
      bnam := GetElementEditValues(LinksTo(ElementByPath(e, 'BNAM')), 'EDID');
      cnam := LinksTo(ElementByPath(e, 'CNAM'));
      conditions := ElementByPath(e, 'Conditions');
      if not Assigned(conditions) then begin
        Add(e, 'Conditions', True);
        conditions := ElementByPath(e, 'Conditions');
        cc := ElementByIndex(conditions, 0);
      end;
      if bnam = 'CraftingTanningRack' then
        TanningRackConditions(cobj, conditions)
      else if bnam = 'CraftingSmithingForge' then 
        SmithingForgeConditions(cnam, conditions)
      else if bnam = 'CraftingSmithingSmelter' then
        SmithingSmelterConditions(cobj, conditions);
      if Assigned(cc) then
        Remove(cc);
    end;
  end;
  
  // final messages
  AddMessage(#13#10);
  AddMessage('----------------------------------------------------------');
  AddMessage('The CCOR Compatibility Script is done.');
  if patchedfiles = 1 then
    AddMessage('Made 1 file compatible.')
  else if patchedfiles > 1 then
    AddMessage('Made '+IntToStr(patchedfiles)+' files compatible.');
  AddMessage(#13#10);
  
end;

end.