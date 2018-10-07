class Yad < Formula
  desc "Yet Another Dialog, a fork of Zenity: GTK+ dialog boxes for the command-line"
  homepage "https://github.com/v1cont/yad.git"
  url "https://github.com/v1cont/yad/archive/v0.40.3.tar.gz"
  sha256 "a63a88ea1946a6ba5d45921abed6b53558215ca4b93b4cd7205de00e9a4848bb"

  head do
    url "https://github.com/v1cont/yad.git"
  end

  depends_on "pkg-config" => :build
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "gettext" => :build
  depends_on "intltool" => :build
  depends_on "itstool" => :build
  depends_on "gtk+3"

  # to be submitted upstream, just a way to disable X11 dependency
  patch :p0, :DATA

  def install
    ENV.prepend_path "PKG_CONFIG_PATH", "/opt/X11/lib/pkgconfig"
    system "gettextize"
    inreplace "configure.ac", "AC_CONFIG_FILES([ po/Makefile.in", "AC_CONFIG_FILES(["
    inreplace "configure.ac", "IT_PROG_INTLTOOL([0.40.0])", ""
    system "autoreconf -ivf"
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "--with-gtk=gtk3"
    inreplace "Makefile", "SUBDIRS = src po data", "SUBDIRS = src data"
    system "make", "install"
  end

  test do
    system "#{bin}/yad", "--help"
  end
end

__END__
diff -Naur src/main.c src.mod/main.c
--- src/main.c	2018-01-20 11:26:14.000000000 +0100
+++ src.mod/main.c	2018-10-07 11:33:21.000000000 +0200
@@ -28,7 +28,9 @@
 
 #ifndef G_OS_WIN32
 # include <sys/shm.h>
-# include <gdk/gdkx.h>
+#ifdef GDK_WINDOWING_X11
+#include <gdk/gdkx.h>
+#endif
 #endif
 
 #include "yad.h"
@@ -46,6 +48,7 @@
 gint t_sem;
 
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
 static void
 sa_usr1 (gint sig)
 {
@@ -64,6 +67,7 @@
     yad_exit (YAD_RESPONSE_CANCEL);
 }
 #endif
+#endif
 
 static gboolean
 keys_cb (GtkWidget *w, GdkEventKey *ev, gpointer d)
@@ -269,6 +273,7 @@
     case YAD_MODE_MULTI_PROGRESS:
       mw = multi_progress_create_widget (dlg);
       break;
+#ifdef GDK_WINDOWING_X11
     case YAD_MODE_NOTEBOOK:
       if (options.plug == -1)
         mw = notebook_create_widget (dlg);
@@ -277,6 +282,7 @@
       if (options.plug == -1)
         mw = paned_create_widget (dlg);
       break;
+#endif
     case YAD_MODE_PICTURE:
       mw = picture_create_widget (dlg);
       break;
@@ -646,6 +652,7 @@
     }
 
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
   /* print xid */
   if (options.print_xid)
     {
@@ -667,6 +674,7 @@
         }
     }
 #endif
+#endif
 
 #if GTK_CHECK_VERSION(3,0,0)
   if (css)
@@ -676,6 +684,7 @@
   return dlg;
 }
 
+#ifdef GDK_WINDOWING_X11
 static void
 create_plug (void)
 {
@@ -712,6 +721,7 @@
   tabs[0].xid++;
   shmdt (tabs);
 }
+#endif
 
 void
 yad_print_result (void)
@@ -739,12 +749,14 @@
     case YAD_MODE_LIST:
       list_print_result ();
       break;
+#ifdef GDK_WINDOWING_X11
     case YAD_MODE_NOTEBOOK:
       notebook_print_result ();
       break;
     case YAD_MODE_PANED:
       paned_print_result ();
       break;
+#endif
     case YAD_MODE_SCALE:
       scale_print_result ();
       break;
@@ -879,6 +891,7 @@
     }
 
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
   /* add YAD_PID variable */
   str = g_strdup_printf ("%d", getpid ());
   g_setenv ("YAD_PID", str, TRUE);
@@ -886,7 +899,9 @@
   signal (SIGUSR1, sa_usr1);
   signal (SIGUSR2, sa_usr2);
 #endif
+#endif
 
+#ifdef GDK_WINDOWING_X11
   /* plug mode */
   if (options.plug != -1)
     {
@@ -895,6 +910,7 @@
       shmdt (tabs);
       return ret;
     }
+#endif
 
   switch (options.mode)
     {
@@ -930,11 +946,14 @@
       dialog = create_dialog ();
 
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
       /* add YAD_XID variable */
       str = g_strdup_printf ("0x%X", (guint) GDK_WINDOW_XID (gtk_widget_get_window (dialog)));
       g_setenv ("YAD_XID", str, TRUE);
 #endif
+#endif
 
+#ifdef GDK_WINDOWING_X11
       /* make some specific init actions */
       if (options.mode == YAD_MODE_NOTEBOOK)
         notebook_swallow_childs ();
@@ -942,9 +961,12 @@
         paned_swallow_childs ();
       else if (options.mode == YAD_MODE_PICTURE)
         {
+#endif
           if (options.picture_data.size == YAD_PICTURE_FIT)
             picture_fit_to_window ();
+#ifdef GDK_WINDOWING_X11
         }
+#endif
 
       /* run main loop */
       gtk_main ();
@@ -965,10 +987,12 @@
             }
         }
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
       if (options.mode == YAD_MODE_NOTEBOOK)
         notebook_close_childs ();
       else if (options.mode == YAD_MODE_PANED)
         paned_close_childs ();
+#endif
       /* autokill option for progress dialog */
       if (!options.kill_parent)
         {
diff -Naur src/notebook.c src.mod/notebook.c
--- src/notebook.c	2018-01-20 11:26:14.000000000 +0100
+++ src.mod/notebook.c	2018-10-07 10:56:10.000000000 +0200
@@ -26,13 +26,16 @@
 #include <sys/ipc.h>
 #include <sys/shm.h>
 
+#ifdef GDK_WINDOWING_X11
 #include <X11/Xlib.h>
 #include <X11/Xatom.h>
 #include <X11/Xutil.h>
+#endif
 #include <gdk/gdk.h>
 
 #include "yad.h"
 
+#ifdef GDK_WINDOWING_X11
 static GtkWidget *notebook;
 
 GtkWidget *
@@ -145,3 +148,4 @@
   shmctl (tabs[0].pid, IPC_RMID, &buf);
   shmdt (tabs);
 }
+#endif
diff -Naur src/option.c src.mod/option.c
--- src/option.c	2018-01-20 11:26:14.000000000 +0100
+++ src.mod/option.c	2018-10-07 11:09:51.000000000 +0200
@@ -39,16 +39,20 @@
 static gboolean set_scale_value (const gchar *, const gchar *, gpointer, GError **);
 static gboolean set_ellipsize (const gchar *, const gchar *, gpointer, GError **);
 static gboolean set_expander (const gchar *, const gchar *, gpointer, GError **);
+#ifdef GDK_WINDOWING_X11
 static gboolean set_orient (const gchar *, const gchar *, gpointer, GError **);
+#endif
 static gboolean set_print_type (const gchar *, const gchar *, gpointer, GError **);
 static gboolean set_progress_log (const gchar *, const gchar *, gpointer, GError **);
 static gboolean set_size (const gchar *, const gchar *, gpointer, GError **);
 static gboolean set_posx (const gchar *, const gchar *, gpointer, GError **);
 static gboolean set_posy (const gchar *, const gchar *, gpointer, GError **);
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
 static gboolean set_xid_file (const gchar *, const gchar *, gpointer, GError **);
 static gboolean parse_signal (const gchar *, const gchar *, gpointer, GError **);
 #endif
+#endif
 static gboolean add_image_path (const gchar *, const gchar *, gpointer, GError **);
 static gboolean set_complete_type (const gchar *, const gchar *, gpointer, GError **);
 static gboolean set_grid_lines (const gchar *, const gchar *, gpointer, GError **);
@@ -78,9 +82,13 @@
 static gboolean icons_mode = FALSE;
 static gboolean list_mode = FALSE;
 static gboolean multi_progress_mode = FALSE;
+#ifdef GDK_WINDOWING_X11
 static gboolean notebook_mode = FALSE;
+#endif
 static gboolean notification_mode = FALSE;
+#ifdef GDK_WINDOWING_X11
 static gboolean paned_mode = FALSE;
+#endif
 static gboolean picture_mode = FALSE;
 static gboolean print_mode = FALSE;
 static gboolean progress_mode = FALSE;
@@ -168,11 +176,13 @@
   { "tabnum", 0, 0, G_OPTION_ARG_INT, &options.tabnum,
     N_("Tab number of this dialog"), N_("NUMBER") },
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
   { "kill-parent", 0, G_OPTION_FLAG_OPTIONAL_ARG, G_OPTION_ARG_CALLBACK, parse_signal,
     N_("Send SIGNAL to parent"), N_("[SIGNAL]") },
   { "print-xid", 0, G_OPTION_FLAG_OPTIONAL_ARG, G_OPTION_ARG_CALLBACK, set_xid_file,
     N_("Print X Window Id to the file/stderr"), N_("[FILENAME]") },
 #endif
+#endif
   { NULL }
 };
 
@@ -468,12 +478,15 @@
     /* xgettext: no-c-format */
     N_("Dismiss the dialog when 100% of all bars has been reached"), NULL },
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
   { "auto-kill", 0, G_OPTION_FLAG_NOALIAS, G_OPTION_ARG_NONE, &options.progress_data.autokill,
     N_("Kill parent process if cancel button is pressed"), NULL },
 #endif
+#endif
   { NULL }
 };
 
+#ifdef GDK_WINDOWING_X11
 static GOptionEntry notebook_options[] = {
   { "notebook", 0, G_OPTION_FLAG_IN_MAIN, G_OPTION_ARG_NONE, &notebook_mode,
     N_("Display notebook dialog"), NULL },
@@ -487,6 +500,7 @@
     N_("Set active tab"), N_("NUMBER") },
   { NULL }
 };
+#endif
 
 static GOptionEntry notification_options[] = {
   { "notification", 0, G_OPTION_FLAG_IN_MAIN, G_OPTION_ARG_NONE, &notification_mode,
@@ -502,6 +516,7 @@
   { NULL }
 };
 
+#ifdef GDK_WINDOWING_X11
 static GOptionEntry paned_options[] = {
   { "paned", 0, G_OPTION_FLAG_IN_MAIN, G_OPTION_ARG_NONE, &paned_mode,
     N_("Display paned dialog"), NULL },
@@ -511,6 +526,7 @@
     N_("Set initial splitter position"), N_("POS") },
   { NULL }
 };
+#endif
 
 static GOptionEntry picture_options[] = {
   { "picture", 0, G_OPTION_FLAG_IN_MAIN, G_OPTION_ARG_NONE, &picture_mode,
@@ -837,12 +853,14 @@
   return TRUE;
 }
 
+#ifdef GDK_WINDOWING_X11
 static gboolean
 add_tab (const gchar * option_name, const gchar * value, gpointer data, GError ** err)
 {
   options.notebook_data.tabs = g_slist_append (options.notebook_data.tabs, g_strdup (value));
   return TRUE;
 }
+#endif
 
 static gboolean
 add_scale_mark (const gchar * option_name, const gchar * value, gpointer data, GError ** err)
@@ -1017,6 +1035,7 @@
   return TRUE;
 }
 
+#ifdef GDK_WINDOWING_X11
 static gboolean
 set_tab_pos (const gchar * option_name, const gchar * value, gpointer data, GError ** err)
 {
@@ -1033,6 +1052,7 @@
 
   return TRUE;
 }
+#endif
 
 static gboolean
 set_expander (const gchar * option_name, const gchar * value, gpointer data, GError ** err)
@@ -1070,6 +1090,7 @@
   return TRUE;
 }
 
+#ifdef GDK_WINDOWING_X11
 static gboolean
 set_orient (const gchar * option_name, const gchar * value, gpointer data, GError ** err)
 {
@@ -1082,6 +1103,7 @@
 
   return TRUE;
 }
+#endif
 
 static gboolean
 set_print_type (const gchar * option_name, const gchar * value, gpointer data, GError ** err)
@@ -1204,6 +1226,7 @@
 #endif
 
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
 static gboolean
 set_xid_file (const gchar * option_name, const gchar * value, gpointer data, GError ** err)
 {
@@ -1310,6 +1333,7 @@
   return TRUE;
 }
 #endif
+#endif
 
 void
 yad_set_mode (void)
@@ -1338,12 +1362,16 @@
     options.mode = YAD_MODE_LIST;
   else if (multi_progress_mode)
     options.mode = YAD_MODE_MULTI_PROGRESS;
+#ifdef GDK_WINDOWING_X11
   else if (notebook_mode)
     options.mode = YAD_MODE_NOTEBOOK;
+#endif
   else if (notification_mode)
     options.mode = YAD_MODE_NOTIFICATION;
+#ifdef GDK_WINDOWING_X11
   else if (paned_mode)
     options.mode = YAD_MODE_PANED;
+#endif
   else if (picture_mode)
     options.mode = YAD_MODE_PICTURE;
   else if (print_mode)
@@ -1377,10 +1405,12 @@
   options.extra_data = NULL;
   options.gtkrc_file = NULL;
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
   options.kill_parent = 0;
   options.print_xid = FALSE;
   options.xid_file = NULL;
 #endif
+#endif
 
   options.hscroll_policy = GTK_POLICY_AUTOMATIC;
   options.vscroll_policy = GTK_POLICY_AUTOMATIC;
@@ -1572,11 +1602,13 @@
   options.multi_progress_data.bars = NULL;
   options.multi_progress_data.watch_bar = 0;
 
+#ifdef GDK_WINDOWING_X11
   /* Initialize notebook data */
   options.notebook_data.tabs = NULL;
   options.notebook_data.borders = 5;
   options.notebook_data.pos = GTK_POS_TOP;
   options.notebook_data.active = 1;
+#endif
 
   /* Initialize notification data */
   options.notification_data.middle = TRUE;
@@ -1584,9 +1616,11 @@
   options.notification_data.menu = NULL;
   options.notification_data.icon_size = 16;
 
+#ifdef GDK_WINDOWING_X11
   /* Initialize paned data */
   options.paned_data.orient = GTK_ORIENTATION_VERTICAL;
   options.paned_data.splitter = -1;
+#endif
 
   /* Initialize picture data */
   options.picture_data.size = YAD_PICTURE_ORIG;
@@ -1602,8 +1636,10 @@
   options.progress_data.pulsate = FALSE;
   options.progress_data.autoclose = FALSE;
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
   options.progress_data.autokill = FALSE;
 #endif
+#endif
   options.progress_data.rtl = FALSE;
   options.progress_data.log = NULL;
   options.progress_data.log_expanded = FALSE;
@@ -1729,11 +1765,13 @@
   g_option_group_set_translation_domain (a_group, GETTEXT_PACKAGE);
   g_option_context_add_group (tmp_ctx, a_group);
 
+#ifdef GDK_WINDOWING_X11
   /* Adds notebook option entries */
   a_group = g_option_group_new ("notebook", _("Notebook options"), _("Show notebook dialog options"), NULL, NULL);
   g_option_group_add_entries (a_group, notebook_options);
   g_option_group_set_translation_domain (a_group, GETTEXT_PACKAGE);
   g_option_context_add_group (tmp_ctx, a_group);
+#endif
 
   /* Adds notification option entries */
   a_group = g_option_group_new ("notification", _("Notification icon options"),
@@ -1742,11 +1780,13 @@
   g_option_group_set_translation_domain (a_group, GETTEXT_PACKAGE);
   g_option_context_add_group (tmp_ctx, a_group);
 
+#ifdef GDK_WINDOWING_X11
   /* Adds paned option entries */
   a_group = g_option_group_new ("paned", _("Paned dialog options"), _("Show paned dialog options"), NULL, NULL);
   g_option_group_add_entries (a_group, paned_options);
   g_option_group_set_translation_domain (a_group, GETTEXT_PACKAGE);
   g_option_context_add_group (tmp_ctx, a_group);
+#endif
 
   /* Adds picture option entries */
   a_group = g_option_group_new ("picture", _("Picture dialog options"), _("Show picture dialog options"), NULL, NULL);
diff -Naur src/paned.c src.mod/paned.c
--- src/paned.c	2018-01-20 11:26:14.000000000 +0100
+++ src.mod/paned.c	2018-10-07 11:10:50.000000000 +0200
@@ -26,13 +26,16 @@
 #include <sys/ipc.h>
 #include <sys/shm.h>
 
+#ifdef GDK_WINDOWING_X11
 #include <X11/Xlib.h>
 #include <X11/Xatom.h>
 #include <X11/Xutil.h>
+#endif
 #include <gdk/gdk.h>
 
 #include "yad.h"
 
+#ifdef GDK_WINDOWING_X11
 static GtkWidget *paned;
 
 GtkWidget *
@@ -123,3 +126,4 @@
   shmctl (tabs[0].pid, IPC_RMID, &buf);
   shmdt (tabs);
 }
+#endif
diff -Naur src/yad.h src.mod/yad.h
--- src/yad.h	2018-01-20 11:26:14.000000000 +0100
+++ src.mod/yad.h	2018-10-07 11:17:22.000000000 +0200
@@ -25,7 +25,9 @@
 #include <sys/types.h>
 #include <sys/ipc.h>
 
+#ifdef GDK_WINDOWING_X11
 #include <gdk/gdkx.h>
+#endif
 
 #include <gtk/gtk.h>
 #include <glib/gi18n.h>
@@ -482,9 +484,13 @@
   YadIconsData icons_data;
   YadListData list_data;
   YadMultiProgressData multi_progress_data;
+#ifdef GDK_WINDOWING_X11
   YadNotebookData notebook_data;
+#endif
   YadNotificationData notification_data;
+#ifdef GDK_WINDOWING_X11
   YadPanedData paned_data;
+#endif
   YadPictureData picture_data;
   YadPrintData print_data;
   YadProgressData progress_data;
@@ -507,7 +513,9 @@
 
 #ifndef G_OS_WIN32
   guint kill_parent;
+#ifdef GDK_WINDOWING_X11
   gboolean print_xid;
+#endif
   gchar *xid_file;
 #endif
 } YadOptions;
@@ -538,7 +546,7 @@
 
 typedef struct {
   pid_t pid;
-  Window xid;
+  guintptr xid;
 } YadNTabs;
 
 /* pointer to shared memory for tabbed dialog */
@@ -566,16 +574,20 @@
 GtkWidget *icons_create_widget (GtkWidget *dlg);
 GtkWidget *list_create_widget (GtkWidget *dlg);
 GtkWidget *multi_progress_create_widget (GtkWidget *dlg);
+#ifdef GDK_WINDOWING_X11
 GtkWidget *notebook_create_widget (GtkWidget *dlg);
 GtkWidget *paned_create_widget (GtkWidget *dlg);
+#endif
 GtkWidget *picture_create_widget (GtkWidget *dlg);
 GtkWidget *progress_create_widget (GtkWidget *dlg);
 GtkWidget *scale_create_widget (GtkWidget *dlg);
 GtkWidget *text_create_widget (GtkWidget *dlg);
 
 gboolean file_confirm_overwrite (GtkWidget *dlg);
+#ifdef GDK_WINDOWING_X11
 void notebook_swallow_childs (void);
 void paned_swallow_childs (void);
+#endif
 void picture_fit_to_window (void);
 
 void calendar_print_result (void);
@@ -585,8 +597,10 @@
 void font_print_result (void);
 void form_print_result (void);
 void list_print_result (void);
+#ifdef GDK_WINDOWING_X11
 void notebook_print_result (void);
 void paned_print_result (void);
+#endif
 void scale_print_result (void);
 void text_print_result (void);
 
@@ -598,8 +612,10 @@
 
 gboolean yad_send_notify (gboolean);
 
+#ifdef GDK_WINDOWING_X11
 void notebook_close_childs (void);
 void paned_close_childs (void);
+#endif
 
 void read_settings (void);
 void write_settings (void);
