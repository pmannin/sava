! sava.csc
! Ristikoiden SAhalinja valinta ja VAunutus
! Copyright (C) 2008-13, MP Soft Oy, Finland
!-----------------------------------------------------------------------

set App_Title "SAVA"
call SAVA
exit

!-----------------------------------------------------------------------
function SAVA _
  n b_loop
!-----------------------------------------------------------------------

  call Sava_Hundegger_Init

  set b_loop true
  loop n (b_loop)

    call SaVa_Init

    if (App_Data["Lomake"] = "SAHAUS")
      call Form_SAHAUS
      set b_loop (FormAction$ = "APPLY")

    elseif (App_Data["Lomake"] = "KAPULAT")
      call Loop_KAPULAT

    elseif (App_Data["Lomake"] = "ASETUS")
      call Form_ASETUS

    else
      error ("Huono lomake '" & App_Data["Lomake"] & "'.")
    endif

  endloop
  
  call SaVa_Write

end function

!-----------------------------------------------------------------------
function SaVa_Init
!-----------------------------------------------------------------------
  del App_Reg[]
  set App_Reg[] App_Reg_Init[]
  getreg App_Reg[] "SaVa\"
  set P_Form_SAHAUS[] P_Form_App[]
  set P_Form_KAPULAT[] P_Form_App[]
  set P_Form_ASETUS[] P_Form_App[]
  call F_DebugMenu
  refresh all
end function

!-----------------------------------------------------------------------
table P_Form_App
  "Width" "1024px"
  "Height" "786px"
  "ButtonWidth" 80
  "LabelWidth" 25
  "CancelLabel" "Keskeyt‰"
end table

!-----------------------------------------------------------------------
table App_Data
!-----------------------------------------------------------------------
  "Versio" "2.12"
  "Lomake" "SAHAUS"
  "Valittu" ""
  "Tiedosto" ""
  "Sahalinja" ""
end table

!-----------------------------------------------------------------------
table App_Reg_Init
!-----------------------------------------------------------------------
  "CbdHakem" ""
  "BvxSaha" ""
  "CbdSaha1" ""
  "CbdSaha2" ""
  "CbdSaha3" ""
  "CbdBackup" ""
  "CbdDebug" ""
  "CbdCar" 100
  "CbdFixedOrder" true
  "CbdPdfMake" false
  "CbdPdfShow" false
  "CbdGroups" 8
  "MaxRows" 500
  "MaxPino" 15
  "PreMark" false
  "ShowData" false
  "ShowAwk" false
  "BvxXml" false
  "BvxCbd" false
  "Height" "740px"
  "NoBackup" false
  "DebugMenu" false
end table

!-----------------------------------------------------------------------
function Form_SAHAUS
!-----------------------------------------------------------------------

  set cols (P_Matrix_SAHAUS["Columns"])
  set T_Matrix_SAHAUS[""][cols] ""

  set P_Func11["ButtonWidth"] 95
  set P_Func12["ButtonWidth"] 95
  set P_Func13["ButtonWidth"] 95
  set P_Func14["ButtonWidth"] 95
  set P_Func15["ButtonWidth"] 95
  set P_Func21["ButtonWidth"] 95
  set P_Func22["ButtonWidth"] 95
  set P_Func23["ButtonWidth"] 95
  set P_Func24["ButtonWidth"] 95
  set P_Func25["ButtonWidth"] 95
  set P_Func26["ButtonWidth"] 95
  set P_Func27["ButtonWidth"] 95

  set P_Func13["Menu"] "M_Func13"
  set P_Func22["Menu"] "M_Func22"
  set P_Func23["Menu"] "M_Func23"
  set P_Func24["Menu"] "M_Func24"
  set P_Func26["Menu"] "M_Func26"
  set P_Func27["Menu"] "M_Func27"

  form "" P_Form_SAHAUS
    frame
      row 0
        button B_Func11   "Hae ristikot"           P_Func11
        button B_Func12   "Lis‰‰ ristikkoja..."    P_Func12
        button B_Func13   "Poista ristikko..."     P_Func13
        button B_Func14   "Yhdist‰ ristikot"       P_Func14
        button B_Func15   "Asetukset"              P_Func15
        button B_Func24   "Merkkaa sahaukseen..."  P_Func24
      endrow
      row 0
        button B_Func21   "Aseta m‰‰r‰..."         P_Func21
        button B_Func22   "Aseta saha..."          P_Func22
        button B_Func23   "Aseta pino..."          P_Func23
        button B_Func26   "Aseta leima..."         P_Func26
        button B_Func27   "Aseta vaunu..."         P_Func27
        button B_Func25   "Muokkaa kapuloita"      P_Func25
      endrow
    endframe
    matrix T_Matrix_SAHAUS P_Matrix_SAHAUS
  endform

  if (not FormStatus$)
    exit
  endif

end function

!-----------------------------------------------------------------------
function Form_SAHAUS_Exit num
  if (T_Matrix_SAHAUS[] = 0)
    exit call
  endif
  set num 0
  loop path T_Matrix_SAHAUS[]
    if (T_Matrix_SAHAUS[path][-1])
      set num (num+1)
    endif
  endloop
  if (num = 0 and FormAction$ = "OK")
    msgbox warning "Listalta ei valittu yht‰‰n ristikkoa sahaukseen." (App_Title)
    set FormStatus$ false
    exit call
  endif
  if (FormAction$ = "OK")
    call SaVa_Check_Folders
    set FormStatus$ (SaVa_Check_Folders)
  endif
end function

!-----------------------------------------------------------------------
table P_Form_SAHAUS
  "Title" "SAVA - Ristikoiden merkkaus sahaukseen"
  "OkayLabel" "Sahaa merkatut"
  "HelpLabel" "Ohje"
  "LabelAlign" "Right"
  "Table" "App_Data"
  "Function" "Form_SAHAUS_Exit"
end table

!-----------------------------------------------------------------------
table P_Matrix_SAHAUS
  "Column1" -1  "Ristikon tiedosto"  "<"
  "Column2"  0  "Tilaus / Rivi"
  "Column3"  0  "ValmistusPvm"
  "Column4"  0  "M‰‰r‰"
  "Column5"  0  "Saha"
  "Column6"  0  "Pino"
  "Column7"  0  "Leima"
  "Column8"  0  "Vaunun pituus"
  "Column9"  0  "Merkki"
  "Columns"  9
  "Rows" 5
  "Stretch" true
  "Locked" "1 2 3 4 5 6 7 8"
  "Boolean" "9"
  "Sort" "G1 G2 G3 G4 G5 G6 G7 G8 G9"
  "Select" "Multi" "T_Select_SAHAUS"
  !"MenuEnabled" false
  "Column5:Menu" "M_Func22"
  "Column6:Menu" "M_Func23"
  "Column7:Menu" "M_Func26"
  "Column8:Menu" "M_Func27"
end table

!-----------------------------------------------------------------------
function B_Func11 _
  path
!-----------------------------------------------------------------------
  set path (App_Reg["CbdHakem"])
  if (not (path)?)
    msgbox warning "Tulevien CBD tiedostojen hakemistoa '%path%' ei lˆytynyt." (App_Title)
    exit call
  endif
  del t_dir[]
  dir t_dir[] (path & "\*.cbd")
  call Sava_Lisaa_Taulu "t_dir" true
end function

!-----------------------------------------------------------------------
function B_Func12 _
  id
!-----------------------------------------------------------------------
  set SelectDir$ (App_Reg["CbdHakem"])
  set SelectTitle$ "Valitse ristikon CBD tiedosto"
  del t_Select[]
  set SelectTable$ "t_Select"
  select file "Ristikon CBD tiedosto (*.cbd)|*.cbd"
  if (t_Select[] = 0)
    exit call
  endif
  del t_dir[]
  loop id t_Select[]
    dir t_dir[] (t_Select[id])
  endloop
  call SaVa_Lisaa_Taulu "t_dir" false
end function

!-----------------------------------------------------------------------
function SaVa_Lisaa_Taulu t_dir b_msg _
  num max id idx pvm til lkm saha pino merk id2
!-----------------------------------------------------------------------
  set num 0
  set max (App_Reg["MaxRows"]+0)
  set saha ""
  set pino (App_Reg["MaxPino"])
  set merk (App_Reg["PreMark"])
  loop id %t_dir%[]
    set idx (%t_dir%[id])
    set pvm (%t_dir%[id][-1] & "m")
    set til (%t_dir%[id][4])
    if (not T_Matrix_SAHAUS[idx]?)
      set num (num+1)
      del t_cbd[]
      input (%t_dir%[id]) t_cbd[] p_Read_CBD[]
      set id2 (t_cbd[1][1])
      if (t_cbd[id2][4+1] = "")
        set t_cbd[id2][4+1] (t_cbd[1][5+1])
        set t_cbd[id2][5+1] ""
      endif
      set lkm (t_cbd[id2][4+1]+0)
      if (t_cbd[id2][46+1]?)
        if (t_cbd[id2][46+1] ??? "^[0-9][0-9]")
          set pvm (t_cbd[id2][46+1])
        endif
      endif
      set T_Matrix_SAHAUS[idx] (til) (pvm) (lkm) (saha) (pino) "CE" "4000" (merk)
    endif
    if (num = max and b_msg)
      !msgbox warning "Haettujen ristikoiden lukum‰‰r‰ksi rajattiin %num%." (App_Title)
      del t_cbd[]
      del %t_dir%[]
      refresh matrix
      exit call
    endif
  endloop
  del t_cbd[]
  del %t_dir%[]
  refresh matrix
end function

!-----------------------------------------------------------------------
table p_Read_CBD
  "Separator" ","
  "Tail" false
end table

!-----------------------------------------------------------------------
table M_Func13 3
  "Poista valitut listalta"            "VALITUT"
  ---1
  "Poista valitsemattomat listalta"    "EIVALITUT"
  "Poistaa merkkaamattomat listalta"   "SAHAAMATTOMAT"
  ---2
  "Poista kaikki listalta"             "LISTA"
  ---Dbg
  "Debug"                              table "M_Func13_Debug"

end table

!-----------------------------------------------------------------------
table M_Func13_Debug
  "N‰yt‰ APIGlue Debug ikkuna"         "DEBUG"
  "Avaa valitut Notepadiin"            "NOTEPAD"
  "Poista valitut levylt‰"             "DELETEDISK"
end table

!-----------------------------------------------------------------------
function B_Func13 arg id
  if (arg = "LISTA")
    set col P_Matrix_SAHAUS["Columns"]
    del T_Matrix_SAHAUS[]
    del T_Control[]
  elseif (arg = "VALITUT")
    if (not T_Select_SAHAUS[1]?)
      msgbox warning "Valitse ne ristikot, jotka haluat poistaa listalta." (App_Title)
      exit call
    endif
    loop id T_Select_SAHAUS[]
      del T_Matrix_SAHAUS[id]
      del T_Control[id]
    endloop
  elseif (arg = "EIVALITUT")
    if (not T_Select_SAHAUS[1]?)
      msgbox warning "Valitse ne ristikot, jotka haluat s‰ilytt‰‰ listalta." (App_Title)
      exit call
    endif
    del t_tmp[]
    set t_tmp[] T_Matrix_SAHAUS[]
    del T_Matrix_SAHAUS[]
    loop id t_tmp[]
      if (T_Select_SAHAUS[id]?)
        set T_Matrix_SAHAUS[id] t_tmp[id]
      else
        del T_Control[id]
      endif
    endloop
  elseif (arg = "SAHAAMATTOMAT")
    del t_tmp[]
    set t_tmp[] T_Matrix_SAHAUS[]
    del T_Matrix_SAHAUS[]
    loop id t_tmp[]
      if (t_tmp[id][-1])
        set T_Matrix_SAHAUS[id] t_tmp[id]
      else
        del T_Control[id]
      endif
    endloop
  elseif (arg = "NOTEPAD")
    if (not T_Select_SAHAUS[1]?)
      msgbox warning "Valitse ne ristikot, jotka haluat avata Notepadiin." (App_Title)
      exit call
    endif
    set qq '"'
    loop id T_Select_SAHAUS[]
      system "NOWAIT" "notepad.exe" (qq & id & qq)
    endloop
  elseif (arg = "DELETEDISK")
    if (not T_Select_SAHAUS[1]?)
      msgbox warning "Valitse ne ristikot, jotka haluat poistaa levylt‰." (App_Title)
      exit call
    endif
    set qq '"'
    loop id T_Select_SAHAUS[]
      del (id)
      del T_Matrix_SAHAUS[id]
      del T_Control[id]
    endloop
  elseif (arg = "DEBUG")
    debug
  endif
  del t_tmp[]
  refresh matrix
end function

!-----------------------------------------------------------------------
function B_Func14
  call SaVa_Ylista
end function

!-----------------------------------------------------------------------
function B_Func15
  set App_Data["Lomake"] "ASETUS"
  exitform "APPLY"
end function

!-----------------------------------------------------------------------
function B_Func21 id
  if (not T_Select_SAHAUS[1]?)
    msgbox warning "Valitse ne ristikot, joiden lukum‰‰r‰n haluat asettaa." (App_Title)
    exit call
  endif
  set msgbox$ (T_Select_SAHAUS[1][4])
  msgbox input "Anna ristikon lukum‰‰r‰?" (App_Title)
  if (not msgbox$ ??? "^[1-9][0-9]?[0-9]?$")
    msgbox error "Huono lukum‰‰r‰ '%msgbox$%'. Anna lukum‰‰r‰ v‰lilt‰ 1-999." (App_Title)
    exit call
  endif
  loop id T_Select_SAHAUS[]
    set T_Matrix_SAHAUS[id][4] (msgbox$)
  endloop
  refresh matrix
end function

!-----------------------------------------------------------------------
table M_Func22
  "Aseta saha Hundegger"     "H"
  "Aseta saha C3"            "C3"
  "Aseta saha C4"            "C4"
  ---1
  "Oletussahaus (Hundegger)" "~"
end table

!-----------------------------------------------------------------------
function B_Func22 saha id
  if (not T_Select_SAHAUS[1]?)
    msgbox warning "Valitse ne ristikot, joiden sahan haluat asettaa." (App_Title)
    exit call
  endif
  loop id T_Select_SAHAUS[]
    set T_Matrix_SAHAUS[id][5] (saha)
  endloop
  refresh matrix
end function

!-----------------------------------------------------------------------
table M_Func23
   "6 kapulaa"   6
  "12 kapulaa"  12
  "18 kapulaa"  18
  "24 kapulaa"  24
  ---
  "Pinon oletuskorkeus" "OLETUS"
end table

!-----------------------------------------------------------------------
function B_Func23 pino id
  if (T_Select_SAHAUS[] = 0)
    msgbox warning "Valitse ne ristikot, joiden pinon max korkeuden haluat asettaa." (App_Title)
    exit call
  endif
  if (pino = "OLETUS")
    set pino (App_Reg["MaxPino"])
  endif
  loop id T_Select_SAHAUS[]
    set T_Matrix_SAHAUS[id][6] (pino)
  endloop
  refresh matrix
end function

!-----------------------------------------------------------------------
table M_Func24
  "Merkkaa valitut sahaukseen"      "LISAA VALITUT"
  "Poista valitut sahauksesta"      "POISTA VALITUT"
  ---1
  "Merkkaa kaikki sahaukseen"       "LISAA KAIKKI"
  "Poista kaikki sahauksesta"       "POISTA KAIKKI"
end table

!-----------------------------------------------------------------------
function B_Func24 arg id
  if (arg = "LISAA KAIKKI")
    set T_Matrix_SAHAUS[][-1] true
  elseif (arg = "POISTA KAIKKI")
    set T_Matrix_SAHAUS[][-1] false
  elseif (arg = "LISAA VALITUT")
    if (not T_Select_SAHAUS[1]?)
      msgbox warning "Valitse ne ristikot, jotka haluat merkata sahaukseen." (App_Title)
      exit call
    endif
    loop id T_Select_SAHAUS[]
      set T_Matrix_SAHAUS[id][-1] true
    endloop
  elseif (arg = "POISTA VALITUT")
    if (not T_Select_SAHAUS[1]?)
      msgbox warning "Valitse ne ristikot, jotka haluat poistaa sahauksesta." (App_Title)
      exit call
    endif
    loop id T_Select_SAHAUS[]
      set T_Matrix_SAHAUS[id][-1] false
    endloop
  endif
  refresh matrix
end function

!-----------------------------------------------------------------------
function B_Func25
  !if (not T_Select_SAHAUS[1]?)
  !  msgbox warning "Valitse ne ristikot, joiden kapuloita haluat muokata." (App_Title)
  !  exit call
  !endif
  set App_Data["Lomake"] "KAPULAT"
  exitform "APPLY"
end function

!-----------------------------------------------------------------------
table M_Func26
  "CE"
  "CE Porvoo"
end table

!-----------------------------------------------------------------------
function B_Func26 leima id
  if (T_Select_SAHAUS[] = 0)
    msgbox warning "Valitse ne ristikot, joiden leiman haluat asettaa." (App_Title)
    exit call
  endif
  loop id T_Select_SAHAUS[]
    set T_Matrix_SAHAUS[id][7] (leima)
  endloop
  refresh matrix
end function

!-----------------------------------------------------------------------
table M_Func27
  "4000"
  "5000"
  "6000"
end table

!-----------------------------------------------------------------------
function B_Func27 pituus id
  if (T_Select_SAHAUS[] = 0)
    msgbox warning "Valitse ne ristikot, joiden vaunun pituuden haluat asettaa." (App_Title)
    exit call
  endif
  loop id T_Select_SAHAUS[]
    set T_Matrix_SAHAUS[id][8] (pituus)
  endloop
  refresh matrix
end function

!-----------------------------------------------------------------------
function Loop_KAPULAT _
  polku
!-----------------------------------------------------------------------
  set App_Data["Lomake"] "SAHAUS"

  if (T_Select_SAHAUS[] = 0)
    set T_Select_SAHAUS[] T_Matrix_SAHAUS[]
  endif

  loop polku T_Select_SAHAUS[]
    set App_Data["Tiedosto"] (polku)
    set App_Data["Sahalinja"] (T_Select_SAHAUS[polku][5])
    call Form_KAPULAT_Init
    call Form_KAPULAT
    if (not FormStatus$)
      exit call
    endif
    call Form_KAPULAT_Write (polku)
  endloop
end function

!-----------------------------------------------------------------------
function Form_KAPULAT_Init
!-----------------------------------------------------------------------
  call Sava_Read_CBD (App_Data["Tiedosto"]) "T_Matrix_KAPULAT"
end function

!-----------------------------------------------------------------------
function Sava_Read_CBD path t_matrix _
  id pit levl luj rlkm lkm tun saha ryhma liita tun2 aihio
!-----------------------------------------------------------------------
  del t_CBD[]
  input (path) t_CBD[] p_Read_CBD[]

  del t_saw[]
  del t_car[]
  del t_cat[]
  if (T_Control[path]?)
    del t_tmp[]
    split (T_Control[path]) t_ctl[] ";"
    loop id t_ctl[]
      del t_tmp2[]
      split (t_ctl[id]) t_tmp2[] "="
      set id (t_tmp2[1])
      split (t_tmp2[2]) t_tmp3[] "|"
      set t_saw[id] (t_tmp3[1])
      if (t_tmp3[2]?)
        set t_car[id] (t_tmp3[2])
      endif
      if (t_tmp3[3]?)
        set t_cat[id] (t_tmp3[3])
      endif
    endloop
  endif
  
  ! ristikon ajonaikainen lukum‰‰r‰
  set rlkm (T_Matrix_SAHAUS[path][4]+0)

  ! kapuloiden pituudet tunnuksen suhteen
  del t_len[]
  loop id t_CBD[]
    set tun (t_CBD[id][42+1])
    set pit (t_CBD[id][7+1])
    set t_len[tun] (pit)
  endloop

  del t_DEF[]
  del %t_matrix%[]
  loop id t_CBD[]
    ! pituus (7), leveys (8), lujuus (29)ja tunnus (42)
    set pit (t_CBD[id][7+1])
    set lev (t_CBD[id][8+1])
    set luj (t_CBD[id][29+1])
    set tun (t_CBD[id][42+1])
    ! loven pituus (21), loven leveys (22)
    set lox (t_CBD[id][21+1]+0)
    set loy (t_CBD[id][22+1]+0)
    ! lukum‰‰r‰ (3, 4, 5, 35)
    if (t_CBD[id][35+1]+0 > 0)
      set lkm (t_CBD[id][35+1] * rlkm)
    else
      set lkm (t_CBD[id][3+1] * rlkm)
    endif
    ! sahalinja (1|2)
    if (App_Data["Sahalinja"] <> "")
      set saha (App_Data["Sahalinja"])
    elseif (t_saw[tun]?)
      set saha (t_saw[tun])
    elseif (tun ??? "[0-9]+[AY]")
      set saha "C3"
    else
      set saha "H"
    endif
    ! k‰rryryhm‰
    if (t_car[tun]?)
      set ryhma (t_car[tun])
    else
      set ryhma "1"
    endif
    ! liitos
    set liita ""
    if (t_cat[tun]?)
      if (t_cat[tun] <> "")
        if (t_cat[tun] <> "-")
          set tun2 (t_cat[tun])
          set liita ("+ " & tun2)
          set pit (pit + t_len[tun2])
        else
          set liita (t_cat[tun])
        endif
      endif
    endif
    set t_DEF[id] (saha) (ryhma) (liita)
    ! lovi
    if (lox > 0 and loy > 0)
      set lovi (loy & "x" & lox)
    else
      set lovi ""
    endif
    ! sama aihio
    set aihio ""
    ! kapulan tunnus, saha, ryhma, lujuus, leveys, pituus ja lukum‰‰r‰
    if (liita = "-")
      set %t_matrix%[id] (tun) "" "" (liita) "" "" "" "" (lovi) (aihio)
    else
      set %t_matrix%[id] (tun) (saha) (ryhma) (liita) (luj) (lev) (pit) (lkm) (lovi) (aihio)
    endif
  endloop
end function

!-----------------------------------------------------------------------
function Form_KAPULAT _
  num
!-----------------------------------------------------------------------
  set P_Func31["ButtonWidth"] 90
  set P_Func32["ButtonWidth"] 90
  set P_Func33["ButtonWidth"] 90
  set P_Func34["ButtonWidth"] 90
  set P_Func36["ButtonWidth"] 90
  set P_Func37["ButtonWidth"] 90
  set P_Func38["ButtonWidth"] 90
  set P_Func39["ButtonWidth"] 90

  set P_Func34["Menu"] "M_Func34"
  del M_Func34[]
  loop num (num <= App_Reg["CbdGroups"])
    set M_Func34["K‰rryryhm‰ " & num] (num&"")
  endloop

  set P_Func31["Enabled"] (App_Data["Sahalinja"] = "")
  set P_Func32["Enabled"] (App_Data["Sahalinja"] = "")
  set P_Func39["Enabled"] (App_Data["Sahalinja"] = "")

  form "" P_Form_KAPULAT
    frame
      show "Tiedosto"     "Tiedosto"
      row 0
        button B_Func39   "Saha H"         P_Func39
        button B_Func31   "Saha C3"        P_Func31
        button B_Func32   "Saha C4"        P_Func32
        button B_Func33   "Ei sahausta"    P_Func33
        button B_Func34   "K‰rryryhm‰"     P_Func34
        button B_Func36   "Liit‰"          P_Func36
        button B_Func37   "Oletusarvot"    P_Func37
        button B_Func38   "Sama aihio"     P_Func38
      endrow
    endframe
    matrix T_Matrix_KAPULAT P_Matrix_KAPULAT
  endform
end function

!-----------------------------------------------------------------------
table P_Form_KAPULAT
  "Title" "SAVA - Kapuloiden tietojen muokkaaminen"
  "OkayLabel" "Hyv‰ksy"
  "HelpLabel" "Ohje"
  "LabelAlign" "Right"
  "Table" "App_Data"
  "Function" ""
end table

!-----------------------------------------------------------------------
table P_Matrix_KAPULAT
  "Column1" -1  "Tilausnumeron rivinumero"
  "Column2" 15  "Tunnus"
  "Column3"  0  "Saha"
  "Column4"  0  "K‰rryryhm‰"
  "Column5"  0  "Liit‰"
  "Column6"  0  "Lujuus"
  "Column7"  0  "Leveys"
  "Column8"  0  "Pituus"
  "Column9"  0  "M‰‰r‰"
  "Column10" 0  "Lovi"
  "Column11" 0  "Sama aihio"
  "Columns" 11
  "Rows" 5
  "Stretch" true
  "Locked" "2 3 4 5 6 7 8 9 10 11"
  "Sort" "G1 G2 G3 G4 G5 G6 G7 G8 G9 G10"
  "Select" "Multi" "T_Select_KAPULAT"
  "MenuEnabled" false
end table

!-----------------------------------------------------------------------
function F_Matrix_KAPULAT col val id
  loop id T_Select_KAPULAT[]
    if (T_Matrix_KAPULAT[id][4] = "")
      set T_Matrix_KAPULAT[id][4] "1"
    endif
    set T_Matrix_KAPULAT[id][col] (val)
  endloop
  refresh matrix
end function

!-----------------------------------------------------------------------
function B_Func39
  loop id T_Select_KAPULAT[]
    if (T_Matrix_KAPULAT[id][5] = "---")
      msgbox warning "Liitetty‰ kapulaa ei voi sahata." (App_Title)
      exit call
    endif
  endloop
  call F_Matrix_KAPULAT 3 "H"
end function

!-----------------------------------------------------------------------
function B_Func31
  loop id T_Select_KAPULAT[]
    if (T_Matrix_KAPULAT[id][5] = "---")
      msgbox warning "Liitetty‰ kapulaa ei voi sahata." (App_Title)
      exit call
    endif
  endloop
  call F_Matrix_KAPULAT 3 "C3"
end function

!-----------------------------------------------------------------------
function B_Func32
  loop id T_Select_KAPULAT[]
    if (T_Matrix_KAPULAT[id][5] = "---")
      msgbox warning "Liitetty‰ kapulaa ei voi sahata." (App_Title)
      exit call
    endif
  endloop
  call F_Matrix_KAPULAT 3 "C4"
end function

!-----------------------------------------------------------------------
function B_Func33 id
  loop id T_Select_KAPULAT[]
    ! kerran liitettyj‰ kapuloita ei voi liitt‰‰ uudestaan
    if (T_Matrix_KAPULAT[id][5] <> "")
      msgbox warning "Liitetty‰ kapulaa ei voi poistaa." (App_Title)
      exit call
    endif
  endloop
  call F_Matrix_KAPULAT 3 ""
  call F_Matrix_KAPULAT 4 ""
end function

!-----------------------------------------------------------------------
function B_Func34 val
  call F_Matrix_KAPULAT 4 (val)
end function

!-----------------------------------------------------------------------
function B_Func36 id tun a1 a2 a3 a4
  if (not T_Select_KAPULAT[]?)
    msgbox warning "Valitse ne kaksi kapulaa, jotka haluat liitt‰‰." (App_Title)
    exit call
  elseif (T_Select_KAPULAT[] <> 2)
    msgbox warning "Valitse ne kaksi kapulaa, jotka haluat liitt‰‰." (App_Title)
  endif
  loop id T_Select_KAPULAT[]
    ! kerran liitettyj‰ kapuloita ei voi liitt‰‰ uudestaan
    if (T_Select_KAPULAT[id][5] <> "")
      msgbox warning "Liitettyj‰ kapuloita ei voi liitt‰‰ uudestaan." (App_Title)
      exit call
    endif
    ! kapulan lukum‰‰r‰ ei saa olla tyhj‰
    if (T_Select_KAPULAT[id][9] = "")
      msgbox warning "Kapulan lukum‰‰r‰ ei saa olla tyhj‰." (App_Title)
      exit call
    endif
    ! liitett‰v‰n kapulan saha ei saa olla tyhj‰
    if (T_Select_KAPULAT[id][3] = "")
      msgbox warning "Liitett‰v‰n kapulan saha ei saa olla tyhj‰." (App_Title)
      exit call
    endif
    ! kapuloiden oltava paarteita
    set tun (T_Select_KAPULAT[id][2])
    if (not tun ??? "[0-9][AY]$")
      msgbox warning "Liitett‰vien kapuloiden tulee olla paarteita." (App_Title)
      exit call
    endif
    ! kapuloiden liitospinnan on oltava 90 asteen kulmassa
    set a1 (t_CBD[id][1+9]+0)
    set a2 (t_CBD[id][1+12]+0)
    set a3 (t_CBD[id][1+15]+0)
    set a4 (t_CBD[id][1+18]+0)
    set b_ok false
    set b_ok (b_ok or (a1 = 900 and a2 = 0))
    set b_ok (b_ok or (a2 = 900 and a1 = 0))
    set b_ok (b_ok or (a3 = 900 and a4 = 0))
    set b_ok (b_ok or (a4 = 900 and a3 = 0))
    if (not b_ok)
      msgbox warning ("Liitett‰v‰ kapula '%tun%' ei sis‰ll‰ suoraa p‰‰t‰.^J" & _
                      "(a1=%a1%, a2=%a2%, a3=%a3%, a4=%a4%)") (App_Title)
      exit call
    endif
  endloop
  ! kapuloiden leveys on oltava sama
  set id1 (T_Select_KAPULAT[1][1])
  set id2 (T_Select_KAPULAT[2][1])
  if (T_Select_KAPULAT[id1][7] <> T_Select_KAPULAT[id2][7])
    msgbox warning "Kapuloiden leveys tulee olla sama." (App_Title)
    exit call
  endif
  ! uuden kapulan pituus ei saa ylitt‰‰ vaunun maksimipituutta 5200
  !if (T_Matrix_KAPULAT[id1][8]+T_Matrix_KAPULAT[id2][8] >= 5200)
  !  msgbox warning "Kapuloiden yhteispituus on yli 5200 mm." (App_Title)
  !  exit call
  !endif
  ! kapuloiden lukum‰‰r‰ pit‰‰ olla sama
  if (T_Matrix_KAPULAT[id1][9] <> T_Matrix_KAPULAT[id2][9])
    msgbox warning "Kapuloiden lukum‰‰r‰ tulee olla sama." (App_Title)
    exit call
  endif
  ! liitetyn kapulan tunnus
  set T_Matrix_KAPULAT[id1][5] ("+ " & T_Select_KAPULAT[id2][2])
  ! suurin lujuus
  if (T_Matrix_KAPULAT[id1][6] < T_Matrix_KAPULAT[id2][6])
    set T_Matrix_KAPULAT[id1][6] (T_Matrix_KAPULAT[id2][6])
  endif
  ! pituudet yhteen
  set T_Matrix_KAPULAT[id1][8] (T_Matrix_KAPULAT[id1][8] + T_Matrix_KAPULAT[id2][8])
  ! tyhj‰‰ liitetty kapula
  set T_Matrix_KAPULAT[id2][3] "" "" "-" "" "" "" ""
  refresh matrix
end function

!-----------------------------------------------------------------------
function B_Func37 id saha karry
  !loop id T_Matrix_KAPULAT[]
  !  set T_Matrix_KAPULAT[id][3] (t_DEF[id][2]) (t_DEF[id][3]) (t_DEF[id][4])
  !endloop
  call Form_KAPULAT_Init
  refresh matrix
end function

!-----------------------------------------------------------------------
function B_Func38 id tun a1 a2 a3 a4
  if (not T_Select_KAPULAT[]?)
    msgbox warning "Valitse ne kaksi kapulaa, joilla on sama aihio." (App_Title)
    exit call
  elseif (T_Select_KAPULAT[] <> 2)
    msgbox warning "Valitse ne kaksi kapulaa, joilla on sama aihio." (App_Title)
  endif
  loop id T_Select_KAPULAT[]
    set tun (T_Select_KAPULAT[id][2])
    ! kerran liitetty‰ kapulaa ei saa valita
    if (T_Select_KAPULAT[id][5] <> "")
      msgbox warning "Liitetty‰ kapulaa '%tun%' ei voi valita." (App_Title)
      exit call
    endif
    ! kapulan lukum‰‰r‰ ei saa olla tyhj‰
    if (T_Select_KAPULAT[id][9] = "")
      msgbox warning "Kapulan '%tun%' lukum‰‰r‰ ei voi olla tyhj‰." (App_Title)
      exit call
    endif
    ! kapulalla ei saa olla samaa aihiota
    if (T_Select_KAPULAT[id][11] <> "")
      msgbox warning "Saman aihion omaavaa kapulaa '%tun%' ei voi valita." (App_Title)
      exit call
    endif
    ! kapulan saha tulee olla C4
    if (T_Select_KAPULAT[id][3] <> "C4")
      msgbox warning "Kapulan '%tun%' saha ei ole 'C4'." (App_Title)
      exit call
    endif
  endloop
  set id1 (T_Select_KAPULAT[1][1])
  set id2 (T_Select_KAPULAT[2][1])
  if (T_Select_KAPULAT[id1][10] = "")
    set id2 (T_Select_KAPULAT[1][1])
    set id1 (T_Select_KAPULAT[2][1])
  endif
  ! toisessa kapulassa tulee olla lovi
  if (T_Select_KAPULAT[id1][10] = "" and T_Select_KAPULAT[id2][10] = "")
    msgbox warning "Toisessa kapulassa tulee olla lovi" (App_Title)
    exit call
  endif
  ! kapuloiden leveys on oltava sama
  if (T_Select_KAPULAT[id1][7] <> T_Select_KAPULAT[id2][7])
    msgbox warning "Kapuloiden leveys tulee olla sama." (App_Title)
    exit call
  endif
  ! kapuloiden lukum‰‰r‰ pit‰‰ olla sama
  if (T_Matrix_KAPULAT[id1][-1] <> T_Matrix_KAPULAT[id2][-1])
    msgbox warning "Kapuloiden lukum‰‰r‰ tulee olla sama." (App_Title)
    exit call
  endif

  ! liitetyn kapulan tunnus
  set T_Matrix_KAPULAT[id1][11] ("+ " & T_Select_KAPULAT[id2][2])
  ! suurin lujuus
  if (T_Matrix_KAPULAT[id1][6] < T_Matrix_KAPULAT[id2][6])
    set T_Matrix_KAPULAT[id1][6] (T_Matrix_KAPULAT[id2][6])
  endif
  ! pituudet yhteen
  set T_Matrix_KAPULAT[id1][8] (T_Matrix_KAPULAT[id1][8] + T_Matrix_KAPULAT[id2][8])
  ! tyhj‰‰ liitetty kapula
  set T_Matrix_KAPULAT[id2][3] "" "" "" "" "" "" "" "" "-"
  refresh matrix
end function

!-----------------------------------------------------------------------
function Form_KAPULAT_Write path _
  data id tunnus saha ryhma
!-----------------------------------------------------------------------
  set data ""
  loop id T_Matrix_KAPULAT[]
    set tunnus (T_Matrix_KAPULAT[id][2])
    set saha   (T_Matrix_KAPULAT[id][3])
    set ryhma  (T_Matrix_KAPULAT[id][4])
    set liita  (T_Matrix_KAPULAT[id][5])
    subst liita "+ " ""
    if (saha <> t_DEF[id][2] or ryhma <> t_DEF[id][3] or liita <> t_DEF[id][4])
      if (data <> "")
        set data (data & ";")
      endif
      set data (data & tunnus & "=" & saha & "|" & ryhma & "|" & liita)
    endif
  endloop
  if (data <> "")
    set T_Control[path] (data)
  endif
end function

!-----------------------------------------------------------------------
function Form_ASETUS
!-----------------------------------------------------------------------
  set App_Data["Lomake"] "SAHAUS"

  set P_CbdHakem["LabelWidth"] 30
  set P_CbdHakem["LabelAlign"] "Right"
  set P_CbdHakem["ButtonWidth"] 90
  set P_MaxRows["LabelWidth"] 80
  set P_MaxRows["Function"] "F_MaxRows"
  set P_CbdGroups["LabelWidth"] 80
  set P_CbdGroups["Function"] "F_CbdGroups"
  set P_PreMark["LabelWidth"] 80
  set P_PreMark["LabelAlign"] "Right"
  set P_80["LabelWidth"] 80
  set P_60["LabelWidth"] 60
  set P_MaxPino["LabelWidth"] 80
  set P_MaxPino["Locked"] true
  set P_CbdCar["LabelWidth"] 80
  set P_CbdCar["Function"] "F_CbdCar"
  set P_LeftAlign["LabelAlign"] "Left"
  set P_Settings["ButtonWidth"] 70
  set P_CbdPdfMake[] P_80[]
  set P_CbdPdfMake["Function"] F_CbdPdfMake
  set P_CbdPdfShow[] P_80[]
  call F_CbdPdfMake
  
  form "" P_Form_ASETUS
    frame "Hakemistot"
      row 0 10
        query "CbdHakem"  "Tulevat CBD tiedostot"              P_CbdHakem
        button B_CbdHakem "Vaihda"                             P_CbdHakem
      endrow
      row 0 10
        query "BvxSaha"   "Sahan Hundegger BVX tiedostot"      P_CbdHakem
        button B_BvxSaha  "Vaihda"                             P_CbdHakem
      endrow
      row 0 10
        query "CbdSaha1"  "Sahan C3 CBD tiedostot"             P_CbdHakem
        button B_CbdSaha1 "Vaihda"                             P_CbdHakem
      endrow
      row 0 10
        query "CbdSaha2"  "Sahan C4 CBD tiedostot"             P_CbdHakem
        button B_CbdSaha2 "Vaihda"                             P_CbdHakem
      endrow
      row 0 10
        query "CbdSaha3"  "Poistettujen kapuloiden tiedostot"  P_CbdHakem
        button B_CbdSaha3 "Vaihda"                             P_CbdHakem
      endrow
      row 0 10
        query "CbdBackup" "Tiedostojen varmistus"              P_CbdHakem
        button B_CbdBackup "Vaihda"                            P_CbdHakem
      endrow
    endframe
    frame "Optiot"
      row 50
        query "MaxRows"            "Haettavien ristikoiden max lukum‰‰r‰"    P_MaxRows
        query "PreMark"            "Merkkaa luetut ristikot sahaukseen"      P_PreMark
      endrow
      row 50
        menu  "MaxPino"  M_MaxPino "Pinon kapuloiden max lukum‰‰r‰n oletus"  P_MaxPino
        query "CbdCar"             "K‰rryjen aloitusnumero"                  P_CbdCar
      endrow
      row 50
        query "Height"             "Lomakkeiden ikkunan korkeus"             P_80
        query "CbdFixedOrder"      "K‰yt‰ 'FixedOrder' rakennetta"           P_80
      endrow
      row 0
        query "CbdPdfMake"         "Tee PDF tiedosto"                        P_CbdPdfMake
        query "CbdPdfShow"         "N‰yt‰ PDF tiedosto"                      P_CbdPdfShow
      endrow
      row 0
        query "CbdGroups"          "K‰rryryhmien lukum‰‰r‰"                  P_CbdGroups
        label
      endrow
    endframe
    frame "Debug"
      row 0
        query "NoBackup"           "ƒl‰ siirr‰ CDB tiedostoa"                P_80
        query "DebugMenu"          "N‰yt‰ Debug valikko"                     P_80
      endrow
      row 0
        query "ShowData"           "N‰yt‰ AWK ohjaustiedosto"                P_80
        query "ShowAwk"            "N‰yt‰ AWK ohjelman suoritus"             P_80
      endrow
      row 40 10
        label                      "AWK ohjelman j‰ljitys"
        query "CbdDebug"           ""
        label                      " (C=CBDt,O=Ohjaus,P=Pinot,K=Kaistat,V=Vaunut)"  P_LeftAlign
      endrow
      row 0
        query "BvxXml"             "Tee Huddeger kansioon XML tiedosto"      P_80
        query "BvxCbd"             "Tee Huddeger kansioon CBD tiedosto"      P_80
      endrow
    endframe
    row 0
      show   App_Data["Versio"]    "Ohjelman versio"                         P_60
      button B_SaveSettings        "Tallenna asetukset..."                   P_Settings
      button B_ReadSettings        "Lue asetukset..."                        P_Settings
      button B_InitSettings        "Alusta asetukset"                        P_Settings
    endrow
  endform

  if (not FormStatus$)
    exit call
  endif

  setreg App_Reg[] "SaVa\"

end function

!-----------------------------------------------------------------------
function Form_ASETUS_Exit msg
  set msg ""
  if (not (App_Reg["CbdHakem"])?)
    set path (App_Reg["CbdHakem"])
    set msg (msg & "^JTulevien CBD tiedostojen hakemistoa '%path%' ei lˆytynyt.")
  endif
  if (not (App_Reg["BvxSaha"])?)
    set path (App_Reg["BvxSaha"])
    set msg (msg & "^JSahan Hundegger tiedostojen hakemistoa '%path%' ei lˆytynyt.")
  endif
  if (not (App_Reg["CbdSaha1"])?)
    set path (App_Reg["CbdSaha1"])
    set msg (msg & "^JSahan 1 CBD tiedostojen hakemistoa '%path%' ei lˆytynyt.")
  endif
  if (not (App_Reg["CbdSaha2"])?)
    set path (App_Reg["CbdSaha2"])
    set msg (msg & "^JSahan 2 CBD tiedostojen hakemistoa '%path%' ei lˆytynyt.")
  endif
  if (not (App_Reg["CbdBackup"])?)
    set path (App_Reg["CbdBackup"])
    set msg (msg & "^JCBD tiedostojen varmistushakemistoa '%path%' ei lˆytynyt.")
  endif
  if (not (App_Reg["MaxRows"] ??? "^[0-9]+$"))
    set msg (msg & "^JListan CBD tiedostojen max lukum‰‰r‰n tulee olla numero.")
  endif
  if (not (App_Reg["CbdGroups"] ??? "^[0-9]+$"))
    set msg (msg & "^JK‰rryryhmien lukum‰‰r‰n tulee olla numero.")
  endif
  call F_DebugMenu
  if (msg <> "")
    msgbox warning (msg) (App_Title)
    set FormStatus$ false
  endif
end function

!-----------------------------------------------------------------------
table P_Form_ASETUS
  "Title" "SAVA - Asetustiedot"
  "OkayLabel" "Hyv‰ksy"
  "HelpLabel" "Ohje"
  "LabelAlign" "Right"
  "Table" "App_Reg"
  "Function" Form_ASETUS_Exit
end table

!-----------------------------------------------------------------------
function F_DebugMenu
  if (App_Reg["DebugMenu"])
    set M_Func13["---Debug"] "" ""
    set M_Func13["Debug"] "table" "M_Func13_Debug"
  else
    del M_Func13["---Debug"]
    del M_Func13["Debug"]
  endif
end function

!-----------------------------------------------------------------------
function B_CbdHakem
  if ((App_Reg["CbdHakem"])?)
    set SelectDir$ (App_Reg["CbdHakem"])
  else
    set SelectDir$ (WorkDir$)
  endif
  select dir
  if ((SelectPath$)?)
    set App_Reg["CbdHakem"] (SelectPath$)
  endif
end function

!-----------------------------------------------------------------------
function B_CbdBackup
  if ((App_Reg["CbdBackup"])?)
    set SelectDir$ (App_Reg["CbdBackup"])
  else
    set SelectDir$ (WorkDir$)
  endif
  select dir
  if ((SelectPath$)?)
    set App_Reg["CbdBackup"] (SelectPath$)
  endif
end function

!-----------------------------------------------------------------------
function B_BvxSaha
  if ((App_Reg["BvxSaha"])?)
    set SelectDir$ (App_Reg["BvxSaha"])
  else
    set SelectDir$ (WorkDir$)
  endif
  select dir
  if ((SelectPath$)?)
    set App_Reg["BvxSaha"] (SelectPath$)
  endif
end function

!-----------------------------------------------------------------------
function B_CbdSaha1
  if ((App_Reg["CbdSaha1"])?)
    set SelectDir$ (App_Reg["CbdSaha1"])
  else
    set SelectDir$ (WorkDir$)
  endif
  select dir
  if ((SelectPath$)?)
    set App_Reg["CbdSaha1"] (SelectPath$)
  endif
end function

!-----------------------------------------------------------------------
function B_CbdSaha2
  if ((App_Reg["CbdSaha2"])?)
    set SelectDir$ (App_Reg["CbdSaha2"])
  else
    set SelectDir$ (WorkDir$)
  endif
  select dir
  if ((SelectPath$)?)
    set App_Reg["CbdSaha2"] (SelectPath$)
  endif
end function

!-----------------------------------------------------------------------
function B_CbdSaha3
  if ((App_Reg["CbdSaha3"])?)
    set SelectDir$ (App_Reg["CbdSaha3"])
  else
    set SelectDir$ (WorkDir$)
  endif
  select dir
  if ((SelectPath$)?)
    set App_Reg["CbdSaha3"] (SelectPath$)
  endif
end function

!-----------------------------------------------------------------------
function F_MaxRows
  if (App_Reg["MaxRows"] < 1)
    set App_Reg["MaxRows"] 500
    msgbox warning "Listan CBD tiedostojen max lukum‰‰r‰n tulee olla positiivinen numero." (App_Title)
    refresh
  endif
end function

!-----------------------------------------------------------------------
function F_CbdGroups
  if (App_Reg["CbdGroups"] < 1)
    set App_Reg["CbdGroups"] 8
    msgbox warning "K‰rryryhmien lukum‰‰r‰n tulee olla positiivinen numero." (App_Title)
    refresh
  endif
end function

!-----------------------------------------------------------------------
function F_CbdCar
  if (not App_Reg["CbdCar"] ??? "^[1-9][0-9][0-9]$")
    set App_Reg["CbdCar"] 100
    msgbox warning "K‰rryjen aloitusnumeron tulee olla v‰lilt‰ 100-999." (App_Title)
    refresh
  endif
end function

!-----------------------------------------------------------------------
function F_CbdPdfMake
  set P_CbdPdfShow["Enabled"] (App_Reg["CbdPdfMake"])
  refresh
end function

!-----------------------------------------------------------------------
table M_MaxPino
   "6 kapulaa"   6
  "12 kapulaa"  12
  "18 kapulaa"  18
  "24 kapulaa"  24
end table

!-----------------------------------------------------------------------
function B_SaveSettings
!-----------------------------------------------------------------------
  set SelectDir$ (OpenDir$)
  set SelectFile$ "SaVa.par"
  select save "Asetuksien tiedosto (*.par)|*.par"
  if (SelectPath$ <> "")
    if ((SelectPath$)?)
      msgbox query _
        ("Tiedosto '%SelectPath$%' on jo olemassa.^J" & _
         "Ylikirjoitetaanko tiedosto?") (App_Title)
      if (not msgbox$)
        exit call
      endif
    endif
    del (SelectPath$)
    write (SelectPath$) App_Reg[]
  endif
end function

!-----------------------------------------------------------------------
function B_ReadSettings _
  path
!-----------------------------------------------------------------------
  set SelectDir$ (OpenDir$)
  set SelectFile$ "SaVa.par"
  select file "Asetuksien tiedosto (*.par)|*.par"
  if (SelectPath$ <> "")
    read (SelectPath$) App_Reg[]
  endif
  refresh
end function

!-----------------------------------------------------------------------
function B_InitSettings
!-----------------------------------------------------------------------
  msgbox query "Alustetaanko Windows rekisteri?" (App_Title)
  if (msgbox$)
    delreg "" "SaVa\"
  endif
  if ((OpenDir$ & "\SaVa.par")?)
    msgbox query "Poistetaanko asetustiedosto 'SaVa.par'?" (App_Title)
    if (msgbox$)
      del (OpenDir$ & "\SaVa.par")
    endif
  endif
  call SaVa_Init
end function

!-----------------------------------------------------------------------
table SaVa_Check_Folders
!-----------------------------------------------------------------------
  "CbdHakem"  "Tulevien CBD tiedostojen hakemisto"
  "BvxSaha"   "Sahan Hundegger BVX tiedostojen hakemisto"
  "CbdSaha1"  "Sahan C3 CBD tiedostojen hakemisto"
  "CbdSaha2"  "Sahan C4 CBD tiedostojen hakemisto"
  "CbdSaha3"  "Poistettujen kapuloiden tiedostojen hakemisto"
  "CbdBackup" "Tiedostojen varmistushakemisto"
end table

!-----------------------------------------------------------------------
function SaVa_Check_Folders _
  msg id path desc
!-----------------------------------------------------------------------
  set SaVa_Check_Folders false
  set msg ""
  loop id SaVa_Check_Folders[]
    set path (App_Reg[id])
    set desc (SaVa_Check_Folders[id])
    if (not (path)?)
      set msg (msg & "^J - " & desc & " (" & path & ")")
    endif
  endloop
  if (msg <> "")
    msgbox warning _
      ("Hakemistoja ei lˆytynyt:" & msg & "^JAseta hakemistot asetussivulla.")
    exit call
  endif
  set SaVa_Check_Folders true
end function

!-----------------------------------------------------------------------
function SaVa_Write _
  id folder path saw path2 awk_txt num num2 data awk_log qq sep
!-----------------------------------------------------------------------
  if (T_Matrix_SAHAUS[] = 0)
    exit call
  endif

  set folder (App_Reg["CbdBackup"])
  set awk_txt (TempDir$ & "\SaVa.txt")
  del (awk_txt)
  set sep "^I"

  loop id App_Reg[]
    if (id ?? "Cbd*" or id ?? "Bvx*")
      log (awk_txt) ("Data" & sep & id & sep & App_Reg[id])
    endif
  endloop

  set num 0
  set num2 0
  loop path T_Matrix_SAHAUS[]
    if (T_Matrix_SAHAUS[path][-1])
      set num (num+1)
      ! siirr‰ alkuper‰inen CBD tiedosto backup kansioon
      del t_path[]
      split (path) t_path[] file
      set path2 (folder & "\" & t_path[2] & ".cbd")
      if (App_Reg["NoBackup"])
        set path2 (path)
      else
        del (path2)
        move (path) (path2)
      endif
      ! awk ohjelmalle tiedoston polku
      log (awk_txt) ("Files" & sep & num & sep & path2)
      ! awk ohjelmalle lis‰ohjaus
      ! "Column4" "M‰‰r‰"
      ! "Column5" "Saha"
      ! "Column6" "Pino"
      ! "Column7" "Leima"
      set data ("Lkm=" & T_Matrix_SAHAUS[path][4] & ";")
      if (T_Matrix_SAHAUS[path][5] <> "")
        set data (data & "Saha=" & T_Matrix_SAHAUS[path][5] & ";")
      endif
      set data (data & "Pino=" & T_Matrix_SAHAUS[path][6] & ";")
      set data (data & "Leima=" & T_Matrix_SAHAUS[path][7] & ";")
      set data (data & "Vaunu=" & T_Matrix_SAHAUS[path][8] & ";")
      if (T_Control[path]?)
        set data (data & T_Control[path])
      endif
      if (data <> "")
        log (awk_txt) ("Control" & sep & num & sep & data)
      endif
    endif
  endloop

  if (App_Reg["ShowData"])
    system "notepad.exe" (awk_txt)
  endif

  set awk_par (TempDir$ & "\SaVa.par")
  del (awk_par)

  set qq '"'
  if (App_Reg["ShowAwk"])
    system ("CMD /C " & qq & OpenDir$ & "\sava_awk.bat" & qq & " /P")
  else
    system "min" ("CMD /C " & qq & OpenDir$ & "\sava_awk.bat" & qq)
  endif

  if ((awk_par)?)
    read (awk_par) App_Reg[]
    setreg App_Reg[] "SaVa\"
  endif
  del (awk_par)

  set path (TempDir$ & "\sava_xml.txt")
  if ((path)?)
    del Sava_Hundegger_Files[]
    input (path) Sava_Hundegger_Files[]
    del (path)
    call Sava_Hundegger
  endif

  if (num > 0)
    msgbox info  ("Saha- ja vaunujako tehtiin " & num & " ristikolle.") (App_Title)
  endif

end function

!-----------------------------------------------------------------------
function SaVa_Ylista _
  folder path path2 awk_txt id num data awk_log qq sep order result
!-----------------------------------------------------------------------
  if (not T_Select_SAHAUS[1]?)
    msgbox warning "Valitse ne ristikot, jotka haluat yhdist‰‰." (App_Title)
    exit call
  elseif (T_Select_SAHAUS[] = 1)
    msgbox warning "Yhdistelyyn tarvitaan v‰hint‰‰n kaksi ristikkoa." (App_Title)
    exit call
  endif

  set folder (App_Reg["CbdBackup"])
  if (not (folder)?)
    error "SaVa_Ylista: Varmistuskansiota '%folder%' ei ole olemassa."
  endif

  set awk_txt (TempDir$ & "\ylista.txt")
  del (awk_txt)
  set sep "^I"

  ! tilausnumero 1. ristikosta
  del t_path[]
  split (T_Select_SAHAUS[1]) t_path[] "_"
  set order (t_path[1])
  log (awk_txt) ("Control" & sep & "OrderNo" & sep & order)

  ! tulostiedostot
  del t_path[]
  split (T_Select_SAHAUS[1][1]) t_path[] file
  set path (t_path[1] & "\" & order & "-yhdistetty.cbd")
  del (path)
  log (awk_txt) ("Control" & sep & "Result.cbd" & sep & path)
  set result (path)
  set path (t_path[1] & "\" & order & "-kapulaluettelo.txt")
  del (path)
  log (awk_txt) ("Control" & sep & "Result.txt" & sep & path)

  ! debug kytkimet
  log (awk_txt) ("Control" & sep & "Debug" & sep & App_Reg["CbdDebug"])

  set num 0
  loop path T_Select_SAHAUS[]
    set num (num+1)
    ! siirr‰ alkuper‰inen CBD tiedosto backup kansioon
    if (not App_Reg["NoBackup"])
      del t_path[]
      split (path) t_path[] file
      set path2 (folder & "\" & t_path[2] & ".cbd")
      del (path2)
      move (path) (path2)
    else
      set path2 (path)
    endif
    ! awk ohjelmalle tiedoston polku
    log (awk_txt) ("Files" & sep & path2)
    ! poistetaan ristikko matriisista
    del T_Matrix_SAHAUS[path]
  endloop

  if (App_Reg["ShowData"])
    system "notepad.exe" (awk_txt)
  endif
  
  set qq '"'
  if (App_Reg["ShowAwk"])
    system ("CMD /C " & qq & OpenDir$ & "\ylista_awk.bat" & qq & " /P")
  else
    system "min" ("CMD /C " & qq & OpenDir$ & "\ylista_awk.bat" & qq)
  endif

  del t_dir[]
  dir t_dir[] (result)
  call SaVa_Lisaa_Taulu "t_dir" false

  msgbox info  ("Yhdistelyn tulostiedosto '" & result & "'.") (App_Title)
  refresh matrix
end function

!-----------------------------------------------------------------------
function Sava_Hundegger_Init _
  path
!-----------------------------------------------------------------------
  set path (OpenDir$ & "\Hundegger.xml")
  if (not (path)?)
    error "Hundegger ohjauksen mallinnetiedosto '%path%' puuttuu."
  endif
  read (path)
  if (XML_0003[]?)
    set XML_Part[] XML_0003[]
  else
     error "Huono Hundegger mallinnetiedosto '%path%'. (Part)"
  endif
  if (XML_0005[]?)
    set XML_SawCut[] XML_0005[]
  else
    error "Huono Hundegger mallinnetiedosto '%path%'. (SawCut)"
  endif
  if (XML_0006[]?)
    set XML_Bitmap[] XML_0006[]
  else
    error "Huono Hundegger mallinnetiedosto '%path%'. (Bitmap)"
  endif
  if (XML_0007[]?)
    set XML_Lap[] XML_0007[]
  else
    error "Huono Hundegger mallinnetiedosto '%path%'. (Lap)"
  endif
  if (XML_0008[]?)
    set XML_Drilling[] XML_0008[]
  else
    error "Huono Hundegger mallinnetiedosto '%path%'. (Drilling)"
  endif
  if (XML_0009[]?)
    set XML_TextOutput[] XML_0009[]
  else
    error "Huono Hundegger mallinnetiedosto '%path%'. (TextOutput)"
  endif
  if (XML_0010[]?)
    set XML_FixedOrder[] XML_0010[]
  else
    error "Huono Hundegger mallinnetiedosto '%path%'. (FixedOrder)"
  endif
  del XML_0002["1"]
end function

!-----------------------------------------------------------------------
function Sava_Hundegger _
  id
!-----------------------------------------------------------------------
  ! vaunujen tiedot (kapuloita / vaunu)
  del CarData[]
  set path (TempDir$ & "\CarData.par")
  if ((path)?)
    read (path) CarData[]
    del (path)
  endif

  ! sahaustiedostojen matriisi tyˆnumeroilla indeksoituna
  del t_H_Lista[]
  set t_H_SAHAUS[] T_Matrix_SAHAUS[][2]

  loop id Sava_Hundegger_Files[]
    call Sava_Hundegger_Write (Sava_Hundegger_Files[id])
  endloop
end function

!-----------------------------------------------------------------------
function Sava_Hundegger_Write path _
  work rlkm id num path2
!-----------------------------------------------------------------------
  ! luetaan CBD tiedosto ja kapula ohjaus
  del t_CBD[]
  input (path) t_CBD[] p_Read_CBD[]
  if (not App_Reg["BvxCbd"])
    del (path)
  endif

  del XML_0002[]
  set XML_0002[""][4] ""

  ! Hundegger "H" kapuloiden prosessointi
  del t_H_Kapula_Vaunut[]
  loop id t_CBD[]
    call Sava_MirrorY_Kapula (id)
    call Sava_Write_H_Kapula (id)
  endloop

  subst path ".cbd" ""
  set path (path & t_H_Kapula_Vaunut[] & ".xml")
  del (path)
  write (path) XML[]

  set path2 (path)
  subst path2 ".xml" ".bvx"
  del (path2)
  copy (path) (path2)

  if (not App_Reg["BvxXml"])
    del (path)
  endif
end function

!-----------------------------------------------------------------------
function Sava_MirrorY_Kapula id _
  len wid ang dx dy
!-----------------------------------------------------------------------
  ! kapulan pituus ja leveys
  set len (t_CBD[id][8]+0)
  set wid (t_CBD[id][9]+0)
  ! pisteen 1 tiedot talteen
  set ang (t_CBD[id][10]+0)
  set dx  (t_CBD[id][11]+0)
  set dy  (t_CBD[id][12]+0)
  ! pisteen 4 siirto pisteeseen 1
  set t_CBD[id][10] (t_CBD[id][19]+0)
  set t_CBD[id][11] (t_CBD[id][20]+0)
  set t_CBD[id][12] (t_CBD[id][21]+0)
  ! pisteen 1 siirto pisteeseen 4
  set t_CBD[id][19] (ang)
  set t_CBD[id][20] (dx)
  set t_CBD[id][21] (dy)
  ! pisteen 2 tiedot talteen
  set ang (t_CBD[id][13]+0)
  set dx  (t_CBD[id][14]+0)
  set dy  (t_CBD[id][15]+0)
  ! pisteen 3 siirto pisteeseen 2
  set t_CBD[id][13] (t_CBD[id][16]+0)
  set t_CBD[id][14] (t_CBD[id][17]+0)
  set t_CBD[id][15] (t_CBD[id][18]+0)
  ! pisteen 2 siirto pisteeseen 3
  set t_CBD[id][16] (ang)
  set t_CBD[id][17] (dx)
  set t_CBD[id][18] (dy)
  ! reikien paikat
  if (t_CBD[id][24]+0 > 0)
    !set t_CBD[id][24] (len - t_CBD[id][24])
    set t_CBD[id][25] (wid - t_CBD[id][25])
    !msgbox ("t=" & t_CBD[id][43] & " x=" & t_CBD[id][24] & " y=" & t_CBD[id][25])
  endif
  if (t_CBD[id][26]+0 > 0)
    !set t_CBD[id][26] (len - t_CBD[id][26])
    set t_CBD[id][27] (wid - t_CBD[id][27])
  endif
  if (t_CBD[id][28]+0 > 0)
    !set t_CBD[id][28] (len - t_CBD[id][28])
    set t_CBD[id][29] (wid - t_CBD[id][29])
  endif
end function

!-----------------------------------------------------------------------
function Sava_Write_H_Kapula id _
  t_xml t_xml2 i j a x y len vaunu pk wi tx bmp b_lap n_fixed
!-----------------------------------------------------------------------
  if (not XmlId?)
    set XmlId 1000
  else
    set XmlId (XmlId+10)
  endif

  set NXml   (XmlId)
  set t_xml  ("XML_" & NXml)
  set NXml   (NXml+1)
  set t_xml2 ("XML_" & NXml)
  set %t_xml2%[""][4] ""

  ! kapulan tiedot
  set work (t_CBD[id][2] & ":" & t_CBD[id][3])
  format Date$ "ww\/yy" week
  del t_xml[]
  set t_xml[] XML_Part[][2]
  set t_xml["PartId"       ] (id)
  set t_xml["Width"        ] (t_CBD[id][42]+0)
  set t_xml["Height"       ] (t_CBD[id][9]+0)
  set t_xml["Length"       ] (t_CBD[id][8]+0)
  subst t_xml["Length"] "," "."
  set t_xml["ReqQuantity"  ] (t_CBD[id][36])
  if (not t_CBD[id][43] ?? "*NR")
    set t_xml["Name"       ] (t_CBD[id][43])
  endif
  set t_xml["ReqLength"    ] (t_CBD[id][8]+0)
  subst t_xml["ReqLength"] "," "."
  set t_xml["Grade"        ] (t_CBD[id][30])
  set x (t_CBD[id][45]+0)
  set x (x - t_xml["Height"]/2)
  format x "0"
  set y (t_CBD[id][46]+0)
  format y "0"
  set vaunu (t_CBD[id][37]&"")
  set t_H_Kapula_Vaunut[vaunu] ""
  if (CarData[vaunu]?)
    set pk (CarData[vaunu])
  else
    set pk ""
  endif
  set t_xml["User_Attribut_1"] (vaunu & "," & x & "," & y & "," & pk)
  set t_xml["User_Attribut_2"] "4"
  if (t_CBD[id][3] = "00")
    set wi (t_CBD[id][2] & "-yhdistetty")
  else
    set wi (t_CBD[id][2] & "_" & t_CBD[id][3])
  endif
  if (t_H_SAHAUS[wi][7]?)
    if (t_H_SAHAUS[wi][7] = "6000")
      set t_xml["User_Attribut_2"] "6"
    elseif (t_H_SAHAUS[wi][7] = "5000")
      set t_xml["User_Attribut_2"] "5"
    endif
  endif
  set t_xml["Unit"         ] (work)
  set t_xml["Operations"   ] (t_xml2)

  ! lis‰t‰‰n kapula kapuloiden joukkoon
  set %t_xml%[] XML_Part[]
  loop i %t_xml%[]
    set att (%t_xml%[i])
    if (t_xml[att]?)
      set %t_xml%[i][3] (t_xml[att])
    endif
  endloop
  set i (XML_0002[]+1)
  set XML_0002[i&""] "Part" (t_xml) "TABLE"

  ! katkaisusahaukset (SawCut)
  set len (t_CBD[id][8]+0)
  loop i (i <= 4)
    set j (10 + (i-1)*3)
    set a (t_CBD[id][j+0]/10.0)
    set x (t_CBD[id][j+1])
    if (a > 90)
      set len (len - x)
    endif
  endloop
  call Sava_SawCut_Kapula (id) 1 (len) (t_xml2)
  call Sava_SawCut_Kapula (id) 2 (len) (t_xml2)
  set b_lap ((t_CBD[id][22]+0) > 1)
  call Sava_SawCut_Corner (id) 3
  set n_fixed (Sava_SawCut_Corner)
  call Sava_SawCut_Corner (id) 4
  set n_fixed (n_fixed + Sava_SawCut_Corner)
  if (not (b_lap and App_Reg["CbdFixedOrder"]))
    call Sava_SawCut_Kapula (id) 4 (len) (t_xml2)
    call Sava_SawCut_Kapula (id) 3 (len) (t_xml2)
  endif

  ! Reik‰ (Drilling)
  loop i (i <= 3)
    set j ((i-1)*2)
    if ((t_CBD[id][24+j]+0) <> 0)
      set NXml (NXml+1)
      set t_xml ("XML_" & NXml)
      set %t_xml%[] XML_Drilling[]
      set %t_xml%["2"][3] (t_CBD[id][24+j]) "attribute" ! LengthMeas = x-mitta
      subst %t_xml%["2"][3] "," "."
      set %t_xml%["3"][3] (t_CBD[id][25+j]) "attribute" ! CrossMeas1 = y-mitta
      subst %t_xml%["3"][3] "," "."
      set %t_xml%["4"][3] (t_CBD[id][44])   "attribute" ! DrillDiam  = halkaisija
      subst %t_xml%["4"][3] "," "."
      set j (%t_xml2%[]+1)
      set %t_xml2%[j&""] "Drilling" (t_xml) "TABLE"
    endif
  endloop

  ! CE leima ja teksti (Bitmap, TextOutput)
  if (t_CBD[id][47] <> "")
    set NXml (NXml+1)
    set t_xml ("XML_" & NXml)
    set %t_xml%[] XML_Bitmap[]
    set x (t_CBD[id][8]/2-300)
    format x "0"
    set %t_xml%["2"][3] (x) "attribute"
    subst %t_xml%["2"][3] "," "."
    set bmp ("C:\SC\" & t_CBD[id][47] & "merkki.bmp")
    set %t_xml%["4"][3] (bmp) "attribute"
    set j (%t_xml2%[]+1)
    set %t_xml2%[j&""] "Bitmap" (t_xml) "TABLE"

    set NXml (NXml+1)
    set t_xml ("XML_" & NXml)
    set %t_xml%[] XML_TextOutput[]
    if (t_CBD[id][47] = "CE")
      set %t_xml%["1"][3] _
      ("0416-CPD-4688 EN 14250:2010   " & work & " " & week & "") "attribute"
    elseif (t_CBD[id][47] = "CE Porvoo")
      set %t_xml%["1"][3] _
      ("0416-CPD-4689 EN 14250:2010   " & work & " " & week & "") "attribute"
    endif
    set %t_xml%["2"][3] (t_CBD[id][42]/2) "attribute"
    subst %t_xml%["2"][3] "," "."
    set %t_xml%["3"][3] (x) "attribute"
    subst %t_xml%["3"][3] "," "."
    set j (%t_xml2%[]+1)
    set %t_xml2%[j&""] "TextOutput" (t_xml) "TABLE"
  endif

  ! Lovi (Lap)
  if (b_lap)
    ! <FixedOrder GroupedOperations="3"/>
    if (App_Reg["CbdFixedOrder"])
      set NXml (NXml+1)
      set t_xml ("XML_" & NXml)
      set %t_xml%[] XML_FixedOrder[]
      set %t_xml%["1"][3] (n_fixed+1)
      set j (%t_xml2%[]+1)
      set %t_xml2%[j&""] "FixedOrder" (t_xml) "TABLE"
    endif
    ! Saw cut corner 4
    if (App_Reg["CbdFixedOrder"])
      call Sava_SawCut_Kapula (id) 4 (len) (t_xml2)
    endif
    ! Lap
    set NXml (NXml+1)
    set t_xml ("XML_" & NXml)
    set %t_xml%[] XML_Lap[]
    set %t_xml%["1"][3] "2" "attribute" ! Reference side
    set %t_xml%["2"][3] (t_CBD[id][23]) "attribute" ! CrossMeas2 - loven y-mitta
    subst %t_xml%["2"][3] "," "."
    ! jos 4. nurkan kulma yli 90 niin lis‰t‰‰n loveen nurkan x-mitta
    set j (10 + (4-1)*3)
    set a (t_CBD[id][j+0]/10.0)
    if (a > 90)
      set x (t_CBD[id][j+1])
    else
      set x 0
    endif
    set %t_xml%["3"][3] (t_CBD[id][22]) "attribute" ! Length     - loven x-mitta
    subst %t_xml%["3"][3] "," "."
    set %t_xml%["4"][3] (t_CBD[id][22]-x)  "attribute" ! LengthMeas - loven x-paikka origosta
    subst %t_xml%["4"][3] "," "."
    set j (%t_xml2%[]+1)
    set %t_xml2%[j&""] "Lap" (t_xml) "TABLE"
    ! Saw cut corner 3
    if (App_Reg["CbdFixedOrder"])
      call Sava_SawCut_Kapula (id) 3 (len) (t_xml2)
    endif
  endif

end function

!-----------------------------------------------------------------------
function Sava_SawCut_Kapula id i len t_xml2 _
  j a x y t_xml yc j2
!-----------------------------------------------------------------------
  set j (10 + (i-1)*3)
  set a (t_CBD[id][j+0]/10.0)
  set x (t_CBD[id][j+1])
  set y (t_CBD[id][j+2])
  if (i = 1 or i = 3)
    set a (180-a)
    set yc (y)
  else
    set j2 (10 + (i-2)*3)
    set yc (t_CBD[id][j2+2])
  endif
  if ((x+0) > 0 or (y+0) > 0)
    set NXml (NXml+1)
    set t_xml ("XML_" & NXml)
    set %t_xml%[] XML_SawCut[]
    set %t_xml%["2"][3] (yc) "attribute"
    set %t_xml%["3"][3] (a) "attribute"
    if (i <= 2)
      set %t_xml%["4"][3] "Left" "attribute"
      set %t_xml%["5"][3] (len) "attribute"
    else
      set %t_xml%["4"][3] "Right" "attribute"
      set %t_xml%["5"][3] "0" "attribute"
    endif
    subst %t_xml%["2"][3] "," "."
    subst %t_xml%["3"][3] "," "."
    subst %t_xml%["5"][3] "," "."
    set j (%t_xml2%[]+1)
    set %t_xml2%[j&""] "SawCut" (t_xml) "TABLE"
  endif
end function

!-----------------------------------------------------------------------
function Sava_SawCut_Corner id i _
  j x y
!-----------------------------------------------------------------------
  set Sava_SawCut_Corner 0
  set j (10 + (i-1)*3)
  set x (t_CBD[id][j+1])
  set y (t_CBD[id][j+2])
  if ((x+0) > 0 or (y+0) > 0)
    set Sava_SawCut_Corner 1
  endif
end function