/*
 * mbids.h - menu and resource identifiers for the MbFolder class.
 *
 * The old SOM 1.0 precompiler emitted these defines into the generated
 * MBFOLDER.IH (they were part of the .SC passthru chain).  The modern SOM
 * compiler generates no such constants, so they live here, included by
 * both the implementation and the resource script.
 *
 * All values are >= WPMENUID_USER (0x6500, wpobject.h:230), so they can
 * never collide with shell-reserved menu IDs.
 */

#ifndef MBIDS_H_INCLUDED
#define MBIDS_H_INCLUDED

#define ID_MBMENU             0x6501   /* the folder menu-bar template       */

#define IDM_FOLDER            0x6601   /* "~Folder" submenu                  */
#define IDM_VIEW              0x6611   /* "~View"   submenu                  */
#define   IDM_VIEW_ICON       0x6612
#define   IDM_VIEW_DETAILS    0x6613
#define   IDM_VIEW_TREE       0x6614
#define IDM_MYHELP            0x6621   /* "~Help"   submenu                  */
#define   IDM_MYHELP_TUTORIAL 0x6622
#define   IDM_PRODUCTINFO     0x6623

#endif /* MBIDS_H_INCLUDED */
