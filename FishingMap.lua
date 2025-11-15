local LMP = LibMapPins
local GPTF = LibGamepadTooltipFilters
local AddonName="FishingMap"
local Localization={
	en={Lake="Lake",Foul="Foul",River="River",Salt="Salt",Oily="Oily",Mystic="Mystic",Running="Running",},
	ru={Lake="озерная вода",Foul="сточная вода",River="речная вода",Salt="морская вода",Oily="маслянистая вода",Mystic="мистическая вода",Running="речная вода",},
	de={Lake="Seewasser",Foul="Brackwasser",River="Flusswasser",Salt="Salzwasser",Oily="Ölwasser",Mystic="Mythenwasser",Running="Fließgewässer",},
	fr={Lake="Lac",Foul="Sale",River="Rivière",Salt="Mer",Oily="Huile",Mystic="Mystique",Running="courante",},
	br={Lake="Lake",Foul="Foul",River="River",Salt="Salt",Oily="Oily",Mystic="Mystic",Running="Running",},
	ua={
		--Lake="озерна вода",Foul="брудна вода",River="річкова вода",Salt="солона вода",Oily="масляниста вода",Mystic="містична вода",Running="проточна вода",
		Lake="Lake",Foul="Foul",River="River",Salt="Salt",Oily="Oily",Mystic="Mystic",Running="Running",},
	it={Lake="Lago",Foul="Acqua Sporca",River="Fiume",Salt="Mare",Oily="Oleosa",Mystic="Mistico",Running="Fluente",},
	es={Lake = "Lago", Foul = "Sucia", River = "Río", Salt = "Salada", Oily = "Aceitosa", Mystic = "Mística", Running = "Corriente",},
	zh={Lake="湖泊",Foul="脏水",River="河流",Salt="咸水",Oily="油污",Mystic="神秘",Running="Running",},
	}
local lang=GetCVar("language.2") if not Localization[lang] then lang="en" end
local function Loc(string)
	return Localization[lang][string] or Localization[lang]["en"] or string
end

local SavedVars, SavedGlobal
local DefaultVars = 
{	
	["AllFish"] = false,
	["FishingMap_Nodes"]=true,
	["fishIconSelected"]={[1]=1,[2]=1,[3]=1,[4]=1},
	["pinsize"] = 20,
	["useCharacterSettings"] = false,
}
local DefaultGlobal = {
	["accountWideProfile"] = DefaultVars,
}

local function GetFMSettings()
	if SavedVars.useCharacterSettings then
		return SavedVars
	else
		return SavedGlobal.accountWideProfile
	end
end

--Data base
local PinManager
local cordsDump = ""
local dumpSize = 0
local UpdatingMapPin,PinId=false,0
local lastLoc = ""
local devMode=false

local FishIcon={
	[1]={--Foul
		[1]="/esoui/art/icons/crafting_slaughterfish.dds",
		[2]="/esoui/art/icons/crafting_fishing_caliginousbristleworm.dds",
		[3]="/esoui/art/icons/crafting_fishing_illuminatedhalosaur.dds",
		},
	[2]={--River
		[1]="/esoui/art/icons/crafting_fishing_river_betty.dds",	
		[2]="/esoui/art/icons/crafting_fishing_salmon.dds",
		},
	[3]={--Lake
		[1]="/esoui/art/icons/crafting_fishing_perch.dds",
		[2]="/esoui/art/icons/crafting_fishing_shad.dds",
		},
	[4]={--Salt
		[1]="/esoui/art/icons/crafting_fishing_merringar.dds",	
		[2]="/esoui/art/icons/crafting_fishing_longfin.dds",		
		},
	}
local FishTypeToID = {
	Foul=1,
	River=2,
	Lake=3,
	Salt=4,
	Oily=1,--clockwork_base
	Mystic=4,--artaeum_base
	Running=2,--? no idea
}
local function FishNameToId(name)
	-- gets globalName
	local failed = true
	for globalName,locName in pairs(Localization[lang]) do 
		if locName == name then
			name = globalName
			failed = false
			break
		end
	end	
	if failed then name = "Salt" end
	return FishTypeToID[name]
end

local FishingZones={
	[2]=471,--Glenumbra
	[4]=472,--Stormhaven
	[5]=473,--Rivenspire
	[9]=477,--Stonefalls crowswood_base=477,
	[10]=478,--Deshaan
	[11]=486,--Malabal Tor
	[14]=475,--Bangkorai
	[15]=480,--Eastmarch
	[16]=481,--Rift
	[17]=474,--Alik'r Desert
	[18]=485,--Greenshade
	[19]=479,--Shadowfen
	[38]=489,--Cyrodiil
	[154]=490,--Coldhabour
	[178]=483,--Auridon
	[179]=487,--Reaper's March
	[180]=484,--Grahtwood
	[501]=916,--Carglorn
	[109]=493,--Bleakrock
	[355]=491,--Stros M'Kai
	[357]=492,--Khenarthi's Roost
	--DLC
	[347]=1186,--Imperial City
	[380]=1340,--Wrothgar
	[443]=1351,--Hew's Bane
	[449]=1431,--Gold Coast
	[468]=1882,--Vvardenfell
	[590]=2027,--Clockwork City
	[617]=2191,--Summerset
	[633]=2240,--Arteum
	[408]=2295,--Murkmire
	[682]=2412,--Northern Elsweyr
	[721]=2566,--Southern Elsweyr
	[744]=2655,--Greymoor: Western Skyrim
	[745]=2655,--Greymoor: Blackreach: Greymoor Caverns
	[784]=2861,--Markarth: The Reach
	[785]=2861,--Markarth: Blackreach: Arkthzand Cavern
	[835]=2981,--Blackwood
	[858]=3144,--Deadlands
	[884]=3269,--High Isle
	[935]=3500,--Firesong
	[959]=3636,--Necrom
	[958]=3636,--Apocrypha
	[982]=3948,--Gold Road
	[1033]=4404,--West/East Solstice
	--[1033]=4460,--East Solstice
	u48_overland_base_west=4404,
	u48_overland_base_east=4460,
}
local ZoneIndexToParentIndex={ 
[1]=4294967296,[2]=4294967296,[3]=154,[4]=4294967296,[5]=4294967296,[6]=17,[7]=179,[8]=14,[9]=4294967296,[10]=4294967296,[11]=4294967296,[12]=10,[13]=16,[14]=4294967296,[15]=4294967296,[16]=4294967296,[17]=4294967296,[18]=4294967296,[19]=4294967296,[20]=180,[21]=180,[22]=5,[23]=11,[24]=19,[25]=18,[26]=11,[27]=4,[28]=2,[29]=4,[30]=19,[31]=4294967296,[32]=5,[33]=2,[34]=14,[35]=14,[37]=18,[38]=4294967296,[39]=19,[41]=10,[42]=10,[43]=9,[45]=9,[46]=46,[47]=4294967296,[49]=49,
[51]=51,[52]=10,[53]=19,[54]=19,[55]=19,[56]=9,[57]=57,[58]=58,[59]=59,[60]=2,[61]=2,[62]=5,[63]=14,[65]=14,[66]=14,[67]=19,[68]=19,[69]=19,[70]=19,[71]=19,[72]=17,[73]=17,[74]=17,[75]=9,[76]=9,[77]=9,[78]=9,[79]=9,[80]=9,[81]=10,[82]=10,[83]=10,[84]=10,[85]=10,[86]=10,[87]=10,[88]=2,[89]=16,[90]=16,[91]=16,[92]=15,[93]=15,[94]=15,[95]=15,[96]=15,[97]=15,[98]=15,[99]=4294967296,[100]=11,
[101]=11,[102]=19,[103]=19,[104]=19,[105]=19,[106]=19,[107]=19,[109]=4294967296,[110]=4294967296,[111]=9,[112]=2,[113]=9,[114]=9,[115]=9,[116]=9,[117]=9,[118]=9,[119]=10,[120]=17,[121]=2,[122]=2,[123]=2,[124]=2,[125]=2,[126]=2,[127]=4,[128]=4,[129]=4,[130]=4,[131]=4,[132]=4,[133]=5,[134]=5,[135]=5,[136]=5,[137]=5,[138]=5,[139]=17,[140]=17,[141]=17,[142]=17,[143]=17,[144]=17,[145]=14,[146]=14,[147]=14,[148]=14,[149]=14,[150]=14,
[151]=15,[152]=16,[154]=4294967296,[155]=15,[157]=15,[158]=15,[159]=15,[160]=15,[161]=15,[162]=15,[163]=154,[164]=154,[165]=154,[166]=154,[167]=154,[168]=154,[169]=154,[170]=154,[171]=154,[173]=154,[175]=11,[176]=11,[177]=178,[178]=4294967296,[179]=682,[180]=4294967296,[181]=181,[182]=9,[184]=178,[185]=180,[186]=178,[187]=178,[188]=178,[189]=178,[190]=178,[191]=178,[192]=178,[193]=178,[194]=178,[195]=178,[196]=178,[197]=16,[198]=16,[199]=16,[200]=10,
[201]=10,[202]=10,[203]=10,[204]=10,[205]=10,[208]=16,[209]=16,[210]=16,[211]=178,[212]=154,[213]=154,[214]=154,[215]=154,[216]=154,[217]=154,[220]=2,[222]=4,[223]=16,[224]=180,[225]=180,[226]=180,[227]=180,[228]=180,[229]=180,[230]=180,[231]=180,[232]=180,[233]=180,[234]=180,[235]=15,[236]=179,[238]=179,[239]=179,[240]=179,[241]=179,[242]=179,[243]=179,[245]=179,[246]=179,[247]=179,[248]=179,[249]=179,[250]=179,
[251]=179,[252]=179,[253]=11,[254]=11,[255]=11,[256]=11,[257]=11,[258]=11,[259]=180,[260]=180,[261]=180,[262]=16,[263]=16,[264]=16,[265]=16,[266]=16,[267]=178,[268]=179,[270]=38,[271]=38,[272]=38,[273]=38,[274]=38,[275]=38,[276]=38,[277]=38,[278]=38,[279]=38,[280]=38,[281]=38,[282]=38,[283]=38,[284]=38,[285]=468,[287]=468,[288]=38,[289]=4294967296,[290]=4294967296,[291]=4294967296,[292]=4294967296,[293]=468,[295]=408,[296]=835,[297]=38,[298]=179,[299]=4294967296,
[302]=38,[303]=38,[304]=38,[305]=4294967296,[306]=4294967296,[307]=4294967296,[308]=306,[310]=178,[311]=2,[312]=9,[315]=18,[316]=18,[317]=180,[318]=18,[319]=18,[320]=18,[321]=18,[322]=18,[323]=18,[324]=154,[325]=18,[327]=16,[328]=18,[329]=179,[330]=179,[332]=332,[333]=17,[335]=17,[337]=4294967296,[338]=338,[339]=18,[340]=18,[341]=18,[342]=18,[343]=18,[344]=18,[347]=38,[348]=14,[350]=5,
[352]=5,[353]=5,[354]=5,[355]=5,[356]=14,[357]=14,[358]=358,[359]=359,[361]=180,[362]=10,[363]=4,[364]=5,[365]=501,[366]=501,[367]=501,[368]=10,[369]=501,[370]=501,[371]=4,[372]=2,[374]=347,[376]=443,[377]=380,[378]=38,[379]=18,[380]=4294967296,[381]=38,[382]=380,[383]=380,[384]=380,[385]=380,[386]=380,[387]=380,[388]=380,[389]=380,[390]=380,[391]=380,[392]=380,[393]=380,[394]=380,[395]=380,[396]=380,[397]=380,[398]=380,[399]=380,[400]=380,
[401]=380,[402]=380,[403]=380,[404]=4294967296,[405]=4294967296,[406]=380,[407]=179,[408]=4294967296,[409]=9,[410]=178,[411]=180,[412]=18,[413]=11,[414]=179,[415]=501,[416]=4,[417]=2,[418]=14,[419]=5,[420]=17,[421]=9,[422]=15,[423]=19,[424]=10,[425]=16,[426]=4294967296,[427]=4294967296,[428]=4294967296,[429]=4294967296,[430]=4294967296,[431]=4294967296,[432]=4294967296,[433]=4294967296,[434]=4294967296,[435]=4294967296,[436]=380,[437]=744,[438]=4294967296,[439]=178,[440]=306,[441]=380,[442]=380,[443]=4294967296,[444]=443,[445]=443,[447]=443,[448]=443,[449]=4294967296,[450]=449,
[451]=449,[452]=449,[453]=449,[454]=449,[455]=449,[456]=449,[457]=449,[458]=449,[459]=15,[460]=449,[461]=449,[462]=4294967296,[463]=4294967296,[464]=19,[465]=443,[466]=443,[467]=19,[468]=4294967296,[499]=180,[500]=501,
[501]=4294967296,[502]=501,[503]=501,[504]=501,[505]=501,[506]=501,[507]=501,[508]=501,[509]=501,[510]=501,[511]=501,[512]=501,[513]=501,[514]=501,[515]=501,[516]=501,[517]=501,[518]=501,[519]=501,[520]=501,[521]=501,[522]=501,[523]=501,[524]=501,[525]=501,[526]=501,[527]=501,[528]=501,[530]=468,[531]=468,[532]=468,[533]=468,[534]=468,[535]=468,[536]=468,[537]=468,[538]=468,[539]=468,[540]=468,[541]=468,[542]=10,[543]=180,[544]=5,[545]=4,[546]=9,[547]=178,[548]=2,
[558]=468,[559]=468,[560]=468,[561]=468,[562]=468,[563]=468,[564]=468,[565]=468,[566]=468,[567]=468,[568]=468,[569]=468,[570]=468,[571]=468,[572]=468,[573]=468,[574]=468,[575]=468,[576]=468,[577]=468,[578]=468,[580]=468,[581]=468,[582]=468,[583]=468,[584]=468,[585]=501,[586]=501,[587]=468,[588]=4294967296,[590]=4294967296,[591]=590,[592]=591,[593]=590,[595]=590,[596]=590,[597]=590,[598]=590,[599]=590,[600]=590,
[601]=590,[602]=590,[605]=468,[609]=591,[613]=501,[615]=14,[616]=4,[617]=4294967296,[619]=617,[620]=617,[621]=617,[622]=633,[623]=617,[624]=617,[625]=617,[626]=617,[627]=617,[628]=617,[629]=617,[630]=617,[631]=617,[632]=617,[633]=4294967296,[634]=617,[635]=617,[636]=617,[637]=617,[638]=617,[639]=617,[640]=617,[641]=4294967296,[642]=617,[643]=617,[644]=617,[645]=633,[646]=633,[649]=449,
[651]=617,[652]=617,[653]=617,[654]=617,[655]=179,[656]=18,[659]=617,[660]=633,[661]=16,[662]=408,[663]=408,[664]=408,[665]=408,[666]=408,[667]=408,[668]=408,[669]=4294967296,[670]=408,[673]=2,[674]=408,[675]=408,[676]=408,[677]=15,[678]=449,[679]=408,[680]=408,[681]=4294967296,[682]=4294967296,[683]=682,[684]=682,[685]=682,[686]=682,[687]=682,[688]=682,[689]=682,[690]=682,[691]=682,[692]=682,[693]=682,[694]=682,[695]=682,[696]=682,[697]=682,[698]=682,[700]=408,
[701]=15,[702]=682,[703]=682,[704]=682,[705]=682,[706]=682,[707]=682,[709]=682,[711]=682,[713]=682,[714]=682,[715]=180,[716]=15,[717]=501,[720]=682,[721]=4294967296,[722]=721,[723]=721,[724]=721,[725]=721,[726]=721,[727]=721,[728]=17,[729]=15,[731]=4,[732]=682,[733]=721,[734]=721,[735]=721,[736]=721,[737]=721,[740]=380,[741]=14,[742]=682,[743]=5,[744]=4294967296,[745]=4294967296,[746]=4294967296,[747]=744,[748]=744,[749]=744,[750]=745,
[751]=744,[753]=745,[754]=745,[755]=744,[757]=744,[758]=744,[759]=744,[760]=744,[761]=4294967296,[762]=745,[763]=744,[764]=745,[766]=744,[767]=744,[768]=745,[770]=15,[771]=16,[772]=4294967296,[773]=721,[774]=721,[776]=744,[777]=745,[778]=380,[779]=14,[780]=744,[782]=4294967296,[783]=4294967296,[784]=4294967296,[785]=4294967296,[786]=784,[787]=784,[788]=784,[790]=784,[791]=784,[793]=784,[795]=744,[796]=744,[797]=745,[798]=744,[799]=784,[800]=784,
[801]=785,[802]=784,[803]=784,[804]=784,[805]=449,[806]=10,[807]=744,[808]=744,[809]=4294967296,[810]=4294967296,[812]=835,[813]=835,[814]=835,[815]=835,[816]=835,[817]=835,[818]=4294967296,[820]=835,[821]=835,[822]=835,[823]=835,[824]=835,[825]=835,[826]=835,[827]=835,[828]=835,[829]=835,[830]=835,[831]=835,[832]=835,[833]=835,[834]=835,[835]=4294967296,[836]=4,[837]=835,[838]=784,[839]=744,[840]=835,[841]=2,[842]=835,[843]=468,[844]=449,[846]=4294967296,[847]=835,[848]=835,[849]=835,[850]=4294967296,
[851]=858,[853]=18,[854]=4294967296,[855]=4294967296,[856]=854,[857]=858,[858]=4294967296,[860]=4294967296,[861]=858,[862]=858,[863]=858,[864]=854,[865]=858,[866]=858,[867]=835,[868]=858,[869]=858,[870]=4294967296,[871]=617,[872]=5,[873]=855,[874]=11,[875]=835,[876]=835,[877]=468,[878]=468,[879]=884,[880]=4294967296,[881]=884,[882]=884,[883]=884,[884]=4294967296,[885]=884,[886]=884,[887]=884,[888]=884,[889]=884,[891]=884,[892]=884,[893]=884,[894]=884,[895]=884,[896]=884,[897]=884,[898]=884,[899]=884,[900]=884,
[901]=884,[902]=884,[903]=884,[904]=855,[905]=858,[906]=884,[907]=306,[909]=884,[910]=884,[912]=884,[913]=2,[914]=14,[915]=931,[917]=931,[918]=931,[919]=931,[921]=931,[922]=931,[923]=931,[924]=931,[925]=931,[926]=884,[927]=931,[928]=884,[929]=931,[930]=884,[931]=931,[932]=931,[933]=931,[934]=931,[935]=9,[936]=16,[937]=4294967296,[938]=179,[939]=959,[941]=959,[942]=960,[943]=960,[944]=959,[945]=959,[946]=959,[947]=959,[948]=960,[949]=960,[950]=960,
[951]=960,[952]=960,[953]=960,[954]=960,[955]=959,[956]=959,[957]=959,[958]=960,[959]=4294967296,[960]=4294967296,[961]=960,[962]=959,[963]=959,[964]=959,[965]=959,[966]=960,[967]=960,[968]=959,[969]=960,[970]=960,[971]=178,[972]=884,[974]=960,[975]=4294967296,[976]=959,[977]=591,[978]=14,[979]=4294967296,[980]=983,[981]=959,[982]=983,[983]=4294967296,[984]=983,[985]=983,[986]=983,[987]=983,[988]=983,[989]=983,[990]=983,[991]=983,[992]=983,[993]=983,[994]=983,[995]=983,[996]=983,[997]=617,[998]=959,[999]=983,[1000]=983,
[1001]=983,[1002]=983,[1003]=99,[1004]=983,[1005]=983,[1006]=983,[1007]=983,[1008]=960,[1009]=1009,[1010]=380,[1011]=931,[1012]=959,[1013]=959,[1014]=4294967296,[1015]=983,[1016]=835,[1017]=408,[1018]=983,[1019]=884,[1020]=17,[1021]=884,[1022]=721,[1023]=767,[1025]=983,[1026]=178,[1027]=983,[1028]=983,[1029]=443,[1030]=617,[1031]=682,[1032]=745,[1033]=16,[1034]=4294967296,[1035]=38,[1036]=5,[1037]=5,[1038]=4294967296,[1039]=4294967296,[1040]=1034,[1041]=1041,[1042]=1034,[1043]=1034,[1044]=1034,[1045]=1034,[1046]=1034,[1047]=1034,[1048]=1034,[1049]=1034,[1050]=1034,
[1051]=1034,[1052]=1034,[1054]=1034,[1055]=1034,[1056]=1034,[1057]=1034,[1058]=1034,[1059]=1034,[1060]=1034,[1061]=1034,[1063]=1034,[1064]=1034,[1065]=855,[1066]=983,[1067]=1034,[1068]=1034,[1069]=1034,[1070]=1034,[1071]=835,[1072]=1034,
}
local FishingAchievements={[471]=true,[472]=true,[473]=true,[474]=true,[475]=true,[477]=true,[478]=true,[479]=true,[480]=true,[481]=true,[483]=true,[484]=true,[485]=true,[486]=true,[487]=true,[489]=true,[490]=true,[491]=true,[492]=true,[493]=true,[916]=true,[1186]=true,[1339]=true,[1340]=true,[1351]=true,[1431]=true,[1882]=true,[2191]=true,[2240]=true,[2295]=true,[2412]=true,[2566]=true,[2655]=true,[2861]=true,[2981]=true,[3144]=true,[3269]=true,[3500]=true,[3636]=true,[3948]=true,[4404]=true,[4460]=true}
local FishingBugFix={[473]={[3]="River"},[2027]={[8]="Oily"},[472]={[1]="Foul"}}--unsure if needed
local FishingPinData={name="FishingMap_Nodes",done=false,pin={},maxDistance=0.05,level=101,texture="/esoui/art/icons/achievements_indexicon_fishing_up.dds",k=1.25,}
local function GetFishingAchievement(subzone)

	local id=FishingZones[subzone] or FishingZones[GetCurrentMapZoneIndex()] or FishingZones[ZoneIndexToParentIndex[GetCurrentMapZoneIndex()]]
	if id then
		local total={Lake=0,Foul=0,River=0,Salt=0,Oily=0,Mystic=0,Running=0}
		for i=1,GetAchievementNumCriteria(id) do
			local AchName,a,b=GetAchievementCriterion(id,i)
			if FishingBugFix[id] and FishingBugFix[id][i] then
				total[ FishingBugFix[id][i] ]=total[ FishingBugFix[id][i] ]+b-a
			else
				for water in pairs(total) do
					if string.match(AchName,"("..Loc(water)..")")~=nil then
						total[water]=total[water]+b-a
					end
				end
			end
		end
		total.Salt=total.Salt+total.Mystic total.Foul=total.Foul+total.Oily total.River=total.River+total.Running
		if GetFMSettings().AllFish then return {[1]=true,[2]=true,[3]=true,[4]=true} end
		return {[1]=total.Foul>0,[2]=total.River>0,[3]=total.Lake>0,[4]=total.Salt>0}
	end
	return false
end

--Callbacks
local function MapPinAddCallback()
	if UpdatingMapPin==true or GetMapType()>MAPTYPE_ZONE or not PinManager:IsCustomPinEnabled(FishingPinData.id) then return end
	local MapContentType=GetMapContentType()
	if not IsPlayerActivated() then
		UpdatingMapPin=true
		EVENT_MANAGER:RegisterForEvent(AddonName.."_MapPin_".."1",EVENT_PLAYER_ACTIVATED,
			function()
				EVENT_MANAGER:UnregisterForEvent(AddonName.."_Pin_".."1",EVENT_PLAYER_ACTIVATED)
				UpdatingMapPin=false MapPinAddCallback()
			end)
		return
	end
	UpdatingMapPin=true

	local mapData=nil 
	local notDone=true
	local function MakePins()
		if mapData and notDone then
			for i1,pinData in pairs(mapData) do
				if notDone[ pinData[3] ] then
					FishingPinData.texture=FishIcon[pinData[3]][GetFMSettings().fishIconSelected[pinData[3]]]
					PinManager:CreatePin(_G[FishingPinData.name],{[1]=1,texture=FishIcon[pinData[3]][GetFMSettings().fishIconSelected[pinData[3]]]},pinData[1],pinData[2])
				end
			end
		end
	end
	local subzone = GetMapTileTexture():match("[^\\/]+$"):lower():gsub("%.dds$", ""):gsub("_[0-9]+$", "")
	if subzone == "u48_overland_base" then 
		subzone = "u48_overland_base_east" 
		mapData=FishingMapNodes[subzone]
		notDone=GetFishingAchievement(subzone)
		MakePins()
		subzone = "u48_overland_base_west" 
	end
	
	mapData=FishingMapNodes[subzone]
	notDone=GetFishingAchievement(subzone)
	MakePins()
	UpdatingMapPin=false
end

local function GetToolTipText()
return zo_iconFormat(FishIcon[1][GetFMSettings().fishIconSelected[1]],35,35).." "..Loc("Foul").."\n"
	 ..zo_iconFormat(FishIcon[2][GetFMSettings().fishIconSelected[2]],35,35).." "..Loc("River").."\n"
	 ..zo_iconFormat(FishIcon[3][GetFMSettings().fishIconSelected[3]],35,35).." "..Loc("Lake").."\n"
	 ..zo_iconFormat(FishIcon[4][GetFMSettings().fishIconSelected[4]],35,35).." "..Loc("Salt")
end
local function updatePinSize(n)
	GetFMSettings().pinsize=n
	if ZO_MapPin.PIN_DATA[FishingPinData.id] and FishingPinData.k then ZO_MapPin.PIN_DATA[FishingPinData.id].size=n*FishingPinData.k end
	LMP:RefreshPins(FishingPinData.name)--PinManager:RefreshCustomPins()
end

local function SettingsMenu()
	local LHAS = LibHarvensAddonSettings
   
    local settings = LHAS:AddAddon("Fishing Map")
    if not settings then return end
	
	local label = {
        type = LHAS.ST_LABEL,
        label = "Go To \n Map -> Options -> Filters \n To Turn On & Off",
    }
    settings:AddSetting(label)
	local checkbox = {--Fishing
        type = LHAS.ST_CHECKBOX,
        label = "Show All Fish", 
		tooltip = "When Off will only show fish you need to collect.",
		--default = false, 
        setFunction = function(value)
           GetFMSettings().AllFish = value
		   LMP:RefreshPins(FishingPinData.name)
        end,
        getFunction = function()
            return GetFMSettings().AllFish
        end,
    }
	settings:AddSetting(checkbox)
	--Slider to Adjust Pin Size
    local slider = {
        type = LHAS.ST_SLIDER,
        label = "Pin Size \n Small <- -> Large",
		tooltip = "Default is 20",
        setFunction = function(value)
           updatePinSize(value)
        end,
        getFunction = function()
            return GetFMSettings().pinsize
        end,
        min = 16,
        max = 40,
        step = 1
    }
    settings:AddSetting(slider)
for i = 1, #FishIcon do
	local items = FishIcon[i]
	local label = ""
	if i==1 then label="Foul" end 
	if i==2 then label="River" end 
	if i==3 then label="Lake" end
	if i==4 then label="Salt" end
	local IconSelect = {
		type = LHAS.ST_ICONPICKER,
		label = label,
		items = items,
		getFunction = function()
			return GetFMSettings().fishIconSelected[i]
		end,
		setFunction = function(combobox, index, item)
			GetFMSettings().fishIconSelected[i]=index
			PinManager:RefreshCustomPins(_G[FishingPinData.name])
		end,
	}
	settings:AddSetting(IconSelect)
end
	local label = {
        type = LHAS.ST_LABEL,
        label = "Found a Missing Fishing Hole? \nStand in the Middle of it \n and type '/fmloc 1' in chat to Log it.",
    }
    settings:AddSetting(label)

	local button = {
            type = LHAS.ST_BUTTON,
            label = "Submit Logged",
            tooltip = "Open link then click submit \n Type '/fmclear' in chat to clear logged holes",
            buttonText = "Open URL",
            clickHandler = function(control, button)
                RequestOpenUnsafeURL(--[["https://forms.gle/GDKynx11DLHnzKkL8")--]]"https://docs.google.com/forms/d/e/1FAIpQLSczE1-xzjbFgRrXSMdMBxZuQgM2eGnBUpiOFvqB8Hve-MfEfA/viewform?usp=pp_url&entry.550722213=" ..cordsDump)
            end,
        }
	settings:AddSetting(button)
	
	--end
end

function math.sign(v)
	return (v >= 0 and 1) or -1
end
function math.round(v, bracket)
	bracket = bracket or 1
	return math.floor(v/bracket + math.sign(v) * 0.5) * bracket
end

local function SetUpSlashCommands()
	SLASH_COMMANDS["/fmpinsize"]=function(n)	
		n=tonumber(n)		
		if n and n>=16 and n<=40 then
			updatePinSize(n)
		else
			d("/fmpinsize {Number} \n Number = 16 to 40")
		end
	end
	
	SLASH_COMMANDS["/fmclear"]=function()
		cordsDump = ""
		d("logged fishingSpots cleared")
	end
	--saves the cord it given by "/fmloc #" and "/fmwploc #"
	local function logCords(n,fileName,cords)
		if n == "?" then 
			d("No Fishing hole detected, please edit in settings\nChange ? to the following\nFoul: 1\nRiver: 2\nLake: 3\nSalt: 4")
		end
		if lastLoc ~= fileName then
			if lastLoc ~= "" then cordsDump = cordsDump .. "},"end
			cordsDump = cordsDump.. fileName .. "={"
			lastLoc = fileName				
		end
		cordsDump = cordsDump .. "{"..cords..","..n.."},"		
		d("Logged")
		--edit bot is capped at 700 so we do this so data isn't deleted
		dumpSize = zo_strlen(cordsDump)
		if dumpSize > 625 then
			d(dumpSize.."/ 700 Reached think about uploading soon")
		end
	end
	
	SLASH_COMMANDS["/fmloc"]=function(n)
		local action, interactableName = GetGameCameraInteractableActionInfo()
		if interactableName =="" or action ~= "Fish" then 
			interactableName = "?" 
		else
			interactableName = FishNameToId(interactableName:gsub(" Fishing Hole", ""))
		end
		local x,y=GetMapPlayerPosition("player")
		local texture = GetMapTileTexture()
	    local fileName = texture:match("[^\\/]+$"):lower()
			fileName = fileName:gsub("%.dds$", "")
			fileName = fileName:gsub("_[0-9]+$", "")
		local xStr = string.gsub(math.floor(x*1000)/1000, "^0%.", ".")
		local yStr = string.gsub(math.floor(y*1000)/1000, "^0%.", ".")
		local cords = xStr..","..yStr
		d(fileName .. "={{"..cords..","..interactableName.."}},")
		n=tonumber(n)	
		if n then
			logCords(interactableName,fileName,cords)
		end
	end
		
	SLASH_COMMANDS["/fmwploc"]=function(n)
		local texturePath = GetMapTileTexture()
		local fileName = texturePath:match("[^\\/]+$"):lower()
		fileName = fileName:gsub("%.dds$", "")
		fileName = fileName:gsub("_[0-9]+$", "")
		local x, y = GetMapPlayerWaypoint()
		local formattedCoords = string.format("%.3f,%.3f", x, y)
		formattedCoords = formattedCoords:gsub("0%.", ".")
		
		d(fileName .. "={" .. formattedCoords .. "},")
		n=tonumber(n)	
		if n and n>=1 and n<=4 then
			logCords(n,fileName,formattedCoords)
		end
	end
	SLASH_COMMANDS["/fmdev"]=function(n)
	devMode = true
	end
end

local function OnAchievementUpdate(achievementId,link)
	local function RefreshPins(name)
		EVENT_MANAGER:RegisterForUpdate("CallLater_"..name, 1000,
		function()
			EVENT_MANAGER:UnregisterForUpdate("CallLater_"..name)
			PinManager:RefreshCustomPins(name)
		end)
	end
	if FishingAchievements[achievementId] and GetFMSettings().FishingMap_Nodes then
		RefreshPins(_G[FishingPinData.name])
	end
end
local function RegisterEvents()
	EVENT_MANAGER:RegisterForEvent(AddonName,EVENT_ACHIEVEMENT_UPDATED,function(_,achievementId,link) OnAchievementUpdate(achievementId)end)
	EVENT_MANAGER:RegisterForEvent(AddonName,EVENT_ACHIEVEMENT_AWARDED,function(_,_,_,achievementId,link) OnAchievementUpdate(achievementId)end)
end
local PinTooltipCreator={
	tooltip=1,
	creator=function(pin)
		--if devMode then
			local _, pinTag=pin:GetPinTypeAndTag()
			local name,icon
			icon=pinTag.texture
			name="X: "..pin.normalizedX.." Y: "..pin.normalizedY
			if IsInGamepadPreferredMode() or IsConsoleUI() then
				ZO_MapLocationTooltip_Gamepad:LayoutIconStringLine(ZO_MapLocationTooltip_Gamepad.tooltip, icon, zo_strformat("<<1>>", name), ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("mapLocationTooltipWayshrineHeader"))
			else
				InformationTooltip:AddLine(zo_strformat("<<1>> <<2>>",zo_iconFormat(icon,24,24), name), "ZoFontGameOutline", ZO_SELECTED_TEXT:UnpackRGB())
			end
		--end 
	end
}
local function OnLoad(eventCode,addonName)
	if addonName ~= AddonName then return end
	EVENT_MANAGER:UnregisterForEvent(AddonName,EVENT_ADD_ON_LOADED)
	local serverName = GetWorldName()
	SavedGlobal = ZO_SavedVars:NewAccountWide("FishingMapSavedVariables", 1, serverName, DefaultGlobal)
	SavedVars = ZO_SavedVars:NewCharacterIdSettings("FishingMapSavedVariables",1, serverName, SavedGlobal.accountWideProfile) 	
	PinManager=ZO_WorldMap_GetPinManager()
	SettingsMenu()
	RegisterEvents()
	
	FishingPinData.size = FishingPinData.size or GetFMSettings().pinsize*FishingPinData.k
	FishingPinData.id = LMP:AddPinType(FishingPinData.name,function() MapPinAddCallback() end,nil,FishingPinData,PinTooltipCreator)
	PinId = FishingPinData.id
	--pin filter--
	local icon = zo_iconFormat(FishingPinData.def_texture or FishingPinData.texture or "", 24, 24)
    local label = icon .. " Fishing Holes"
	LMP:AddPinFilter(FishingPinData.id, label, false, GetFMSettings())	
	
	if GPTF then GPTF:AddTooltip(FishingPinData.id,GetToolTipText()) end	
	SetUpSlashCommands()
	
end
EVENT_MANAGER:RegisterForEvent(AddonName,EVENT_ADD_ON_LOADED,OnLoad)

