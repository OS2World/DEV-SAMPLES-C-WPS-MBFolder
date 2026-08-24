/*
 * MBFOLDER.C                (c) IBM Japan, 1993             */
/*   (C) Copyright Tokyo Research Laboratory,                 */
/*   IBM Research 1993                                        */
/*                                                            */
/*   1993-01-29(FRI) Toru Aihara                              */
/*     Folder with menu-bar (like PSZFolder)                  */
/*                                                            */
/*   Module Name: MBFOLDER.DLL                                */
/*   Class Name:  MbFolder                                    */
/*############################################################*/
/*#  New features:                                           #*/
/*#   - Menu bar                                             #*/
/*#   - Change views between icon and details views          #*/
/*#     without opening new windows.                         #*/
/*############################################################*/

/*
 * Ported from the SOM 1.0 precompiler layout to modern SOM IDL bindings
 * plus Open Watcom.  Changes against orig\MBFOLDER.C are listed in
 * README.md; behavioural changes: none intended.
 */

/**-----------------------------------------**/
/**  override methods                       **/
/**-----------------------------------------**/
/** Instance method                         **/
/**   wpMenuItemSelected                    **/
/**   wpOpen;                               **/
/**                                         **/
/** Class method                            **/
/**   wpclsInitData                         **/
/**   wpclsUnInitData                       **/
/**-----------------------------------------**/

/*
 * PM/DOS/WPS header prelude.  The SOM 1.0 precompiler emitted these
 * into MBFOLDER.IH (see orig\MBFOLDER.IH lines 17-23); sc does not,
 * so they are carried here instead - BEFORE any class bindings are
 * included, since wpobject.h pulls in <pmstddlg.h>, which needs the
 * base PM types from os2.h.
 */
#define INCL_WIN
#define INCL_DOS
#define INCL_GPIBITMAPS
#define INCL_WPCLASS
#define INCL_WPFOLDER

#include <os2.h>

#define MbFolder_Class_Source
#include "mbfolder.ih"
#include "mbids.h"

/*-------------------------*/
/*-  Global data           */
/*-------------------------*/
HMODULE  hmodThisClass=NULLHANDLE;
PVOID    pmtMenu=NULL;      /* Menubar resource  */
PSZ      pszClassName   = "MbFolder";
PSZ      pszModuleName  = "MBFOLDER.DLL";
PSZ      pszProductInfo = "(C) Copyright IBM Japan 1993\n"
                          "(C) Copyright Tokyo Reserch Laboratory 1993\n"
                          "All rights reserved\n\n"
                          "Author: Toru Aihara\n"
                          "Vnet: AIHARA at TRLVM\n\n"
                          "Class name: MbFolder\n"
                          "Library module: MBFOLDER.DLL\n"
                          "Date: 1993-01-29 09:35";
PSZ      pszSorryInfo   = "This function is not currently available";

/*-------------------------*/
/*-  Function Prototype    */
/*-------------------------*/
VOID     UpdateContainer(MbFolder *somSelf,HWND hwndCnr, ULONG ulView);
HWND     QueryDetailsView(MbFolder *somSelf);


/*-------------------------*/
/*-  Overriding Methos     */
/*-------------------------*/

/*
 *
 *   METHOD:   wpMenuItemSelected                          PUBLIC
 *
 *   PURPOSE:  Processes the user's selections from the context menu.  The
 *             overridden method processes only the added "Lock" item, before
 *             invoking the parent's default processing to handle other items.
 *
 *   INVOKED:  By Workplace Shell, upon selection of a menu item by the user.
 *
 */

SOM_Scope BOOL   SOMLINK mbfolder_wpMenuItemSelected(MbFolder *somSelf,
                HWND hwndFrame,
                ULONG ulMenuId)
{
    HWND   hwndClient;
    HWND   hwndDetailsFrame;
    HWND   hwndMenu;

    /* No instance variables: no somThis (sc emits no MbFolderGetData
     * for a class without data; the old precompiler always did). */
    MbFolderMethodDebug(pszClassName,"mbfolder_wpMenuItemSelected");

    switch(ulMenuId){
      case 0x012F:   /* Open as Icon View */
        if (hwndDetailsFrame = QueryDetailsView(somSelf)){
          if((hwndMenu = WinWindowFromID(hwndDetailsFrame,FID_MENU))&&
             (hwndClient = WinWindowFromID(hwndFrame,FID_CLIENT))){
            if (!WinIsMenuItemChecked(hwndMenu,IDM_VIEW_ICON)){
              UpdateContainer(somSelf,hwndClient,OPEN_CONTENTS);
              WinEnableMenuItem(hwndMenu,IDM_VIEW_ICON,   FALSE);
              WinEnableMenuItem(hwndMenu,IDM_VIEW_DETAILS,TRUE );
              WinCheckMenuItem (hwndMenu,IDM_VIEW_ICON,   TRUE );
              WinCheckMenuItem (hwndMenu,IDM_VIEW_DETAILS,FALSE);
            }
          }
        }
        ulMenuId = 0x0130;
        break;  /* Call default processing */

      case 0x0130:   /* Open as Details View */
        if (hwndDetailsFrame = QueryDetailsView(somSelf)){
          if((hwndMenu = WinWindowFromID(hwndDetailsFrame,FID_MENU))&&
             (hwndClient = WinWindowFromID(hwndFrame,FID_CLIENT))){
            if (!WinIsMenuItemChecked(hwndMenu,IDM_VIEW_DETAILS)){
              UpdateContainer(somSelf,hwndClient,OPEN_DETAILS);
              WinEnableMenuItem(hwndMenu,IDM_VIEW_ICON,   TRUE );
              WinEnableMenuItem(hwndMenu,IDM_VIEW_DETAILS,FALSE);
              WinCheckMenuItem (hwndMenu,IDM_VIEW_ICON,   FALSE);
              WinCheckMenuItem (hwndMenu,IDM_VIEW_DETAILS,TRUE );
            }
          }
        }
        break;  /* Call default processing */

      case IDM_VIEW_ICON:
        if (hwndClient = WinWindowFromID(hwndFrame,FID_CLIENT)){
          UpdateContainer(somSelf,hwndClient,OPEN_CONTENTS);
          if (hwndMenu = WinWindowFromID(hwndFrame,FID_MENU)){
            WinEnableMenuItem(hwndMenu,IDM_VIEW_ICON,   FALSE);
            WinEnableMenuItem(hwndMenu,IDM_VIEW_DETAILS,TRUE );
            WinCheckMenuItem (hwndMenu,IDM_VIEW_ICON,   TRUE );
            WinCheckMenuItem (hwndMenu,IDM_VIEW_DETAILS,FALSE);
          }
        }
        return (TRUE);
        break;

      case IDM_VIEW_DETAILS:
        if (hwndClient = WinWindowFromID(hwndFrame,FID_CLIENT)){
          UpdateContainer(somSelf,hwndClient,OPEN_DETAILS);
          if (hwndMenu = WinWindowFromID(hwndFrame,FID_MENU)){
            WinEnableMenuItem(hwndMenu,IDM_VIEW_ICON,   TRUE );
            WinEnableMenuItem(hwndMenu,IDM_VIEW_DETAILS,FALSE);
            WinCheckMenuItem (hwndMenu,IDM_VIEW_ICON,   FALSE);
            WinCheckMenuItem (hwndMenu,IDM_VIEW_DETAILS,TRUE );
          }
        }
        return (TRUE);
        break;

      case IDM_MYHELP_TUTORIAL:
        WinMessageBox(HWND_DESKTOP,
                      HWND_DESKTOP,
                      pszSorryInfo,
                      pszClassName,
                      0,
                      MB_WARNING | MB_OK);
        return (TRUE);
        break;

      case IDM_PRODUCTINFO:
        WinMessageBox(HWND_DESKTOP,
                      HWND_DESKTOP,
                      pszProductInfo,
                      pszClassName,
                      0,
                      MB_INFORMATION | MB_OK);
        return (TRUE);
        break;

      default:
        break;
    }

    return (parent_wpMenuItemSelected(somSelf,hwndFrame,ulMenuId));
}

/*
 *
 *   METHOD:   wpOpen                                      PUBLIC
 *
 *   PURPOSE:  Only allows a folder to be opened if the folder is unlocked, or
 *             if the user supplies the correct password in response to the
 *             dialog.
 *
 *   INVOKED:  By Workplace Shell, upon selection of the "Open" menu item by
 *             the user.
 *
 */

SOM_Scope HWND   SOMLINK mbfolder_wpOpen(MbFolder *somSelf,
                HWND hwndCnr,
                ULONG ulView,
                ULONG param)
{
    HWND        hwndFrame;
    HWND        hwndClient;
    HWND        hwndMenu;

    /* No instance variables: no somThis. */
    MbFolderMethodDebug(pszClassName,"mbfolder_wpOpen");


    if ((ulView==OPEN_CONTENTS) || (ulView==OPEN_DETAILS)){
      hwndFrame = parent_wpOpen(somSelf,hwndCnr,OPEN_DETAILS,param);
      hwndClient=WinWindowFromID(hwndFrame, FID_CLIENT);
      if(hwndClient){
        UpdateContainer(somSelf,hwndClient,ulView);
        /*- Put menu-bar -*/
        hwndMenu=WinCreateMenu(hwndFrame, pmtMenu); /* Create menu bar #1 */
        WinSendMsg(hwndFrame,WM_UPDATEFRAME,(MPARAM)FCF_MENU,MPVOID);
        if (ulView==OPEN_CONTENTS) {
          WinEnableMenuItem(hwndMenu,IDM_VIEW_ICON,   FALSE);
          WinCheckMenuItem (hwndMenu,IDM_VIEW_ICON,   TRUE );
        }
        else {
          WinEnableMenuItem(hwndMenu,IDM_VIEW_DETAILS,FALSE);
          WinCheckMenuItem (hwndMenu,IDM_VIEW_DETAILS,TRUE );
        }
      }
    }
    else{
      hwndFrame = parent_wpOpen(somSelf,hwndCnr,ulView,param);
    }

    return (hwndFrame);
}


#undef SOM_CurrentClass
#define SOM_CurrentClass SOMMeta
/*
 *
 *   METHOD:   wpclsInitData                               PUBLIC
 *
 *   PURPOSE:  This class method allows the initialization of any class data
 *             items.  The overridden method simply obtains a module handle
 *             to be used when accessing Presentation Manager resources, then
 *             invokes the parent's default processing.
 *
 *   INVOKED:  By the Workplace Shell, upon loading the class DLL.
 *
 */

SOM_Scope void   SOMLINK mbfoldercls_wpclsInitData(M_MbFolder *somSelf)
{
    somId  idClassName;
    PSZ    pszDllPath;

    /* M_MbFolderData *somThis = M_MbFolderGetData(somSelf); */
    M_MbFolderMethodDebug("M_MbFolder","mbfoldercls_wpclsInitData");

    parent_wpclsInitData(somSelf);     /* Default processing first */

    /*
     * PORTING NOTE (zString removal): the original called
     *   zsPathName = _somLocateClassFile(SOMClassMgrObject,
     *                                     SOM_IdFromString(pszClassName), ...)
     * where zsPathName was a zString object from the SOM 1.x class library.
     * With modern C usage bindings somLocateClassFile returns a plain PSZ,
     * and the id helper is somIdFromString (the old spelling was
     * SOM_IdFromString).  The somId is ours to free (SOMFree); the returned
     * path string is owned by the class manager and must NOT be freed here.
     */
    idClassName = somIdFromString(pszClassName);
    pszDllPath  = _somLocateClassFile(SOMClassMgrObject,
                                      idClassName,
                                      MbFolder_MajorVersion,
                                      MbFolder_MinorVersion);

    /*- Obtain DLL module handle -*/
    DosQueryModuleHandle(pszDllPath,&hmodThisClass);
    SOMFree(idClassName);

    /*- Obtain menubar resource -*/
    DosGetResource(hmodThisClass, RT_MENU,
                   ID_MBMENU,
                   &pmtMenu);          /* #1 */

    return;
}

/*
 *
 *   METHOD:   wpclsUnInitData                             PUBLIC
 *
 *   PURPOSE:  This class method allows the release of any class data items
 *             or resources.  The overridden method releases the module handle
 *             obtained by wpclsInitData, then invokes the parent's default
 *             processing.
 *
 *   INVOKED:  By the Workplace Shell, upon unloading the class DLL.
 *
 */

SOM_Scope void   SOMLINK mbfoldercls_wpclsUnInitData(M_MbFolder *somSelf)
{
    /* M_MbFolderData *somThis = M_MbFolderGetData(somSelf); */
    M_MbFolderMethodDebug("M_MbFolder","mbfoldercls_wpclsUnInitData");


    DosFreeResource(pmtMenu);       /* #1 */
    DosFreeModule(hmodThisClass);

    parent_wpclsUnInitData(somSelf);
    return;
}

/***
 *** Ordinary Code Section
 ***
 ***    Any non-method code shold go here.
 ***
 ***/

/*---------------------------------------------------*/
/*- UpdateContainer: Change Container View          -*/
/*---------------------------------------------------*/
VOID     UpdateContainer(MbFolder *somSelf,HWND hwndCnr,ULONG ulView)
{
  CNRINFO      cnrInfo;

  if (WinSendMsg(hwndCnr, CM_QUERYCNRINFO,
                 MPFROMP(&cnrInfo),
                 MPFROMSHORT((SHORT)sizeof(CNRINFO)))){
    cnrInfo.flWindowAttr &= ~((ULONG) ( CV_ICON
                                      | CV_NAME
                                      | CV_TEXT
                                      | CV_TREE
                                      | CV_DETAIL
                                      | CV_MINI
                                      | CV_FLOW ));
    cnrInfo.flWindowAttr |= _wpQueryFldrAttr(somSelf,ulView);
    WinSendMsg(hwndCnr, CM_SETCNRINFO,
               MPFROMP(&cnrInfo),
               MPFROMSHORT(CMA_FLWINDOWATTR));

    WinInvalidateRect(hwndCnr,NULL,TRUE);
  }

  return;
}

/*---------------------------------------------*/
/*- QueryDetailsView: Check the details view  -*/
/*---------------------------------------------*/
HWND QueryDetailsView(MbFolder *somSelf)
{
  PUSEITEM     pUseItem;

  pUseItem=_wpFindUseItem(somSelf,USAGE_OPENVIEW,NULL);

  while (pUseItem) {
    if ( ((PVIEWITEM)(pUseItem+1))->view == OPEN_DETAILS ){
      return(((PVIEWITEM)(pUseItem+1))->handle);
    }
    pUseItem=_wpFindUseItem(somSelf,USAGE_OPENVIEW,pUseItem);
  }

  return(NULLHANDLE); /* Not found */
}

/*-----------------------------------------------------------*/
/*- SOMInitModule: class-library initialization entry point -*/
/*-----------------------------------------------------------*/
/*
 * The SOM kernel runs this export when the class DLL is loaded
 * (see som.md "Class libraries and SOMInitModule"; prototype per
 * toolkit sample os2tk45\samples\rexx\som\animal\sominit.c).
 * It creates the class objects this DLL provides.  Order: the
 * metaclass first, then the instance class (its NewClass body
 * statically references M_MbFolderNewClass).
 *
 * Note: under Open Watcom SOMLINK expands to nothing (somltype.h
 * has no __WATCOMC__ case), so give this entry the system linkage
 * explicitly; the method prototypes are covered by #pragma linkage
 * emitted into mbfolder.ih and by the toolkit headers.
 */
#pragma linkage(SOMInitModule, system)
void SOMLINK SOMInitModule(integer4 majorVersion, integer4 minorVersion)
{
    M_MbFolderNewClass(majorVersion, minorVersion);
    MbFolderNewClass(majorVersion, minorVersion);
}
