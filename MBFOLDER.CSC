##########################################################
#                                                        #
#  MBFOLDER.CSC              (c) IBM Japan, 1993         #
#   (C) Copyright Tokyo Research Laboratory,             #
#   IBM Research 1993                                    #
#                                                        #
#   1993-01-28(THU) Toru Aihara                          #
#     Folder with menu-bar (like PSZFolder)              #
#                                                        #
#   Module Name: MBFOLDER.DLL                            #
#   Class Name:  MbFolder                                #
##########################################################
#  New features:                                         #
#   - Menu bar                                           #
#   - Change views between icon and details views        #
#     without opening new windows.                       #
##########################################################
#  override methods                                      #
#--------------------------------------------------------#
# Instance method                                        #
#   wpMenuItemSelected                                   #
#   wpOpen;                                              #
#                                                        #
# Class method                                           #
#   wpclsInitData                                        #
#   wpclsUnInitData                                      #
##########################################################

#
# Include the class definition file for the parent class
#
include <wpfolder.sc>

#
#   Define the new class
#
class: MbFolder,
       file stem = MBFOLDER,
       external prefix = mbfolder_,
       class prefix = mbfoldercls_,
       major version = 1,
       minor version = 1,
       local;

-- MbFolder is subclassed folder.
-- It is derived as follows:
--        SOMOject
--          - WPObject
--             - WPFileSystem
--                - WPFolder
--                   - MbFolder

#
# Specify the parent class
#
parent: WPFolder;

#
# Specify the release order of new methods
#
###release order: ;

#
# Passthru a debug message box to the .ih file
# (for inclusion in the .c file)
#
passthru: C.h, after;

#define DebugBox(title, text)  WinMessageBox(HWND_DESKTOP,HWND_DESKTOP, \
                               (PSZ) text , (PSZ) title, 0, \
                               MB_OK | MB_INFORMATION )

endpassthru;

#
# Passthru private definitions to the .ph file
# (for inclusion in the .c file)
#
passthru: C.ih;
  #define INCL_WIN
  #define INCL_DOS
  #define INCL_GPIBITMAPS
  #define INCL_WPCLASS
  #define INCL_WPFOLDER

  #include <os2.h>

  #include <pmwp.h>

  #include <string.h>
  #include <stdio.h>
  #include <memory.h>
  #include <stdlib.h>

  /*----------------------------*/
  /*--  Menu id (Resource id) --*/
  /*----------------------------*/
  #define   ID_MBMENU                           0x6501

  /*----------------------------*/
  /*--  Menu cmd (message id) --*/
  /*----------------------------*/
  #define   IDM_FOLDER                          0x6601

  #define   IDM_VIEW                            0x6611
  #define     IDM_VIEW_ICON                     0x6612
  #define     IDM_VIEW_DETAILS                  0x6613
  #define     IDM_VIEW_TREE                     0x6614

  #define   IDM_MYHELP                          0x6621
  #define     IDM_MYHELP_TUTORIAL               0x6622
  #define     IDM_PRODUCTINFO                   0x6623

  /*-----------------------------------*/
  /*--  Keys for save/restore method --*/
  /*-----------------------------------*/

endpassthru;   /* .ih */

#
# Define instance data for the class
#
data:
ULONG   ulContentsView;
-- Current view of 'Contents view'

#
# Define new methods
#
methods:


#
# Specify methods being overridden
#

override wpMenuItemSelected;
--
--  METHOD:   wpMenuItemSelected                          PUBLIC
--
--  PURPOSE:  Processes the user's selections from the context menu.  The
--            overridden method processes only the added "Lock" item, before
--            invoking the parent's default processing to handle other items.
--
--  INVOKED:  By Workplace Shell, upon selection of a menu item by the user.
--

override wpOpen;
--
--  METHOD:   wpOpen                                      PUBLIC
--
--  PURPOSE:  Only allows a folder to be opened if the folder is unlocked, or
--            if the user supplies the correct password in response to the
--            dialog.
--
--  INVOKED:  By Workplace Shell, upon selection of the "Open" menu item by
--            the user.
--

override wpclsInitData, classmethod;
--
--  METHOD:   wpclsInitData                               PUBLIC
--
--  PURPOSE:  This class method allows the initialization of any class data
--            items.  The overridden method simply obtains a module handle
--            to be used when accessing Presentation Manager resources, then
--            invokes the parent's default processing.
--
--  INVOKED:  By the Workplace Shell, upon loading the class DLL.
--

override wpclsUnInitData, classmethod;
--
--  METHOD:   wpclsUnInitData                             PUBLIC
--
--  PURPOSE:  This class method allows the release of any class data items
--            or resources.  The overridden method releases the module handle
--            obtained by wpclsInitData, then invokes the parent's default
--            processing.
--
--  INVOKED:  By the Workplace Shell, upon unloading the class DLL.
--
