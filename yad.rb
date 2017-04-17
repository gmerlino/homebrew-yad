class Yad < Formula
  desc "Yet Another Dialog, a fork of Zenity: GTK+ dialog boxes for the command-line"
  homepage "https://sourceforge.net/projects/yad-dialog/"
  url "https://downloads.sourceforge.net/project/yad-dialog/yad-0.38.2.tar.xz"
  sha256 "91299cba8836b4e510c4527a081d0ad519ad0c6d9f96b3f7f5409acfb66fd5fa"

  head do
    url "http://svn.code.sf.net/p/yad-dialog/code/trunk"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkg-config" => :build
  depends_on "intltool" => :build
  depends_on "itstool" => :build
  depends_on "gtk+3"

  # to be submitted upstream, just a way to disable X11 dependency
  patch :p2, :DATA

  def install
    if build.head?
      system "autoreconf -ivf"
    end
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "--with-gtk=gtk3"
    system "make", "install"
  end

  test do
    system "#{bin}/yad", "--help"
  end
end

__END__
diff --git a/yad-dialog-code/src/main.c b/yad-dialog-code.mod/src/main.c
index cdac888..2c0dc29 100644
--- a/yad-dialog-code/src/main.c
+++ b/yad-dialog-code.mod/src/main.c
@@ -28,7 +28,9 @@
 
 #ifndef G_OS_WIN32
 # include <sys/shm.h>
-# include <gdk/gdkx.h>
+#ifdef GDK_WINDOWING_X11
+#include <gdk/gdkx.h>
+#endif
 #endif
 
 #include "yad.h"
@@ -42,6 +44,7 @@ gint t_sem;
 void print_result (void);
 
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
 static void
 sa_usr1 (gint sig)
 {
@@ -60,6 +63,7 @@ sa_usr2 (gint sig)
     gtk_dialog_response (GTK_DIALOG (dialog), YAD_RESPONSE_CANCEL);
 }
 #endif
+#endif
 
 static void
 btn_cb (GtkWidget *b, gchar *cmd)
@@ -228,6 +232,7 @@ create_layout (GtkWidget *dlg)
     case YAD_MODE_MULTI_PROGRESS:
       mw = multi_progress_create_widget (dlg);
       break;
+#ifdef GDK_WINDOWING_X11
     case YAD_MODE_NOTEBOOK:
       if (options.plug == -1)
         mw = notebook_create_widget (dlg);
@@ -236,6 +241,7 @@ create_layout (GtkWidget *dlg)
       if (options.plug == -1)
         mw = paned_create_widget (dlg);
       break;
+#endif
     case YAD_MODE_PICTURE:
       mw = picture_create_widget (dlg);
       break;
@@ -322,6 +328,7 @@ create_dialog (void)
   gtk_widget_set_name (dlg, "yad-dialog-window");
 
 #ifndef  G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
   /* FIXME: is that very useful !? */
   if (options.parent)
     {
@@ -330,6 +337,7 @@ create_dialog (void)
                                                                             options.parent));
     }
 #endif
+#endif
 
   if (options.data.no_escape)
     g_signal_connect (G_OBJECT (dlg), "close", G_CALLBACK (g_signal_stop_emission_by_name), "close");
@@ -542,6 +550,7 @@ create_dialog (void)
     }
 
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
   /* print xid */
   if (options.print_xid)
     {
@@ -549,10 +558,12 @@ create_dialog (void)
       fflush (stderr);
     }
 #endif
+#endif
 
   return dlg;
 }
 
+#ifdef GDK_WINDOWING_X11
 static void
 create_plug (void)
 {
@@ -584,6 +595,7 @@ create_plug (void)
   tabs[0].xid++;
   shmdt (tabs);
 }
+#endif
 
 void
 print_result (void)
@@ -611,12 +623,14 @@ print_result (void)
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
@@ -750,6 +764,7 @@ main (gint argc, gchar ** argv)
     }
 
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
   /* add YAD_PID variable */
   str = g_strdup_printf ("%d", getpid ());
   g_setenv ("YAD_PID", str, TRUE);
@@ -757,7 +772,9 @@ main (gint argc, gchar ** argv)
   signal (SIGUSR1, sa_usr1);
   signal (SIGUSR2, sa_usr2);
 #endif
+#endif
 
+#ifdef GDK_WINDOWING_X11
   /* plug mode */
   if (options.plug != -1)
     {
@@ -766,6 +783,7 @@ main (gint argc, gchar ** argv)
       shmdt (tabs);
       return ret;
     }
+#endif
 
   switch (options.mode)
     {
@@ -791,11 +809,14 @@ main (gint argc, gchar ** argv)
       gtk_widget_show_all (dialog);
 
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
@@ -803,9 +824,12 @@ main (gint argc, gchar ** argv)
         paned_swallow_childs ();
       else if (options.mode == YAD_MODE_PICTURE)
         {
+#endif
           if (options.picture_data.size == YAD_PICTURE_FIT)
             picture_fit_to_window ();
-        }
+#ifdef GDK_WINDOWING_X11
+	}
+#endif
 
       /* run main loop */
       gtk_main ();
@@ -826,10 +850,12 @@ main (gint argc, gchar ** argv)
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
diff --git a/yad-dialog-code/src/notebook.c b/yad-dialog-code.mod/src/notebook.c
index 0b2e8bc..de1e324 100644
--- a/yad-dialog-code/src/notebook.c
+++ b/yad-dialog-code.mod/src/notebook.c
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
@@ -139,3 +142,4 @@ notebook_close_childs (void)
   shmctl (tabs[0].pid, IPC_RMID, &buf);
   shmdt (tabs);
 }
+#endif
diff --git a/yad-dialog-code/src/option.c b/yad-dialog-code.mod/src/option.c
index d271ed6..f86958d 100644
--- a/yad-dialog-code/src/option.c
+++ b/yad-dialog-code.mod/src/option.c
@@ -39,7 +39,9 @@ static gboolean set_tab_pos (const gchar *, const gchar *, gpointer, GError **);
 static gboolean set_scale_value (const gchar *, const gchar *, gpointer, GError **);
 static gboolean set_ellipsize (const gchar *, const gchar *, gpointer, GError **);
 static gboolean set_expander (const gchar *, const gchar *, gpointer, GError **);
+#ifdef GDK_WINDOWING_X11
 static gboolean set_orient (const gchar *, const gchar *, gpointer, GError **);
+#endif
 static gboolean set_print_type (const gchar *, const gchar *, gpointer, GError **);
 static gboolean set_progress_log (const gchar *, const gchar *, gpointer, GError **);
 static gboolean set_size (const gchar *, const gchar *, gpointer, GError **);
@@ -64,9 +66,13 @@ static gboolean html_mode = FALSE;
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
@@ -144,6 +150,7 @@ static GOptionEntry general_options[] = {
   { "tabnum", 0, 0, G_OPTION_ARG_INT, &options.tabnum,
     N_("Tab nubmer of this dialog"), N_("NUMBER") },
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
   { "parent-win", 0, 0, G_OPTION_ARG_INT, &options.parent,
     N_("XID of parent window"), "XID" },
   { "kill-parent", 0, G_OPTION_FLAG_OPTIONAL_ARG, G_OPTION_ARG_CALLBACK, parse_signal,
@@ -151,6 +158,7 @@ static GOptionEntry general_options[] = {
   { "print-xid", 0, 0, G_OPTION_ARG_NONE, &options.print_xid,
     N_("Print X Window Id to the stderr"), NULL },
 #endif
+#endif
   { "image-path", 0, 0, G_OPTION_ARG_CALLBACK, add_image_path,
     N_("Add path for search icons by name"), N_("PATH") },
   { NULL }
@@ -420,6 +428,7 @@ static GOptionEntry multi_progress_options[] = {
   { NULL }
 };
 
+#ifdef GDK_WINDOWING_X11
 static GOptionEntry notebook_options[] = {
   { "notebook", 0, G_OPTION_FLAG_IN_MAIN, G_OPTION_ARG_NONE, &notebook_mode,
     N_("Display notebook dialog"), NULL },
@@ -431,6 +440,7 @@ static GOptionEntry notebook_options[] = {
     N_("Set tab borders"), N_("NUMBER") },
   { NULL }
 };
+#endif
 
 static GOptionEntry notification_options[] = {
   { "notification", 0, G_OPTION_FLAG_IN_MAIN, G_OPTION_ARG_NONE, &notification_mode,
@@ -444,6 +454,7 @@ static GOptionEntry notification_options[] = {
   { NULL }
 };
 
+#ifdef GDK_WINDOWING_X11
 static GOptionEntry paned_options[] = {
   { "paned", 0, G_OPTION_FLAG_IN_MAIN, G_OPTION_ARG_NONE, &paned_mode,
     N_("Display paned dialog"), NULL },
@@ -453,6 +464,7 @@ static GOptionEntry paned_options[] = {
     N_("Set initial splitter position"), N_("POS") },
   { NULL }
 };
+#endif
 
 static GOptionEntry picture_options[] = {
   { "picture", 0, G_OPTION_FLAG_IN_MAIN, G_OPTION_ARG_NONE, &picture_mode,
@@ -753,12 +765,14 @@ add_bar (const gchar * option_name, const gchar * value, gpointer data, GError *
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
@@ -933,6 +947,7 @@ set_justify (const gchar * option_name, const gchar * value, gpointer data, GErr
   return TRUE;
 }
 
+#ifdef GDK_WINDOWING_X11
 static gboolean
 set_tab_pos (const gchar * option_name, const gchar * value, gpointer data, GError ** err)
 {
@@ -949,6 +964,7 @@ set_tab_pos (const gchar * option_name, const gchar * value, gpointer data, GErr
 
   return TRUE;
 }
+#endif
 
 static gboolean
 set_expander (const gchar * option_name, const gchar * value, gpointer data, GError ** err)
@@ -986,6 +1002,7 @@ set_ellipsize (const gchar * option_name, const gchar * value, gpointer data, GE
   return TRUE;
 }
 
+#ifdef GDK_WINDOWING_X11
 static gboolean
 set_orient (const gchar * option_name, const gchar * value, gpointer data, GError ** err)
 {
@@ -998,6 +1015,7 @@ set_orient (const gchar * option_name, const gchar * value, gpointer data, GErro
 
   return TRUE;
 }
+#endif
 
 static gboolean
 set_print_type (const gchar * option_name, const gchar * value, gpointer data, GError ** err)
@@ -1189,12 +1207,16 @@ yad_set_mode (void)
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
@@ -1220,10 +1242,12 @@ yad_options_init (void)
   options.extra_data = NULL;
   options.gtkrc_file = NULL;
 #ifndef G_OS_WIN32
+#ifdef GDK_WINDOWING_X11
   options.parent = 0;
   options.kill_parent = 0;
   options.print_xid = FALSE;
 #endif
+#endif
 
   /* plug settings */
   options.plug = -1;
@@ -1386,19 +1410,23 @@ yad_options_init (void)
   options.multi_progress_data.bars = NULL;
   options.multi_progress_data.watch_bar = 0;
 
+#ifdef GDK_WINDOWING_X11
   /* Initialize notebook data */
   options.notebook_data.tabs = NULL;
   options.notebook_data.borders = 5;
   options.notebook_data.pos = GTK_POS_TOP;
+#endif
 
   /* Initialize notification data */
   options.notification_data.middle = TRUE;
   options.notification_data.hidden = FALSE;
   options.notification_data.menu = NULL;
 
+#ifdef GDK_WINDOWING_X11
   /* Initialize paned data */
   options.paned_data.orient = GTK_ORIENTATION_VERTICAL;
   options.paned_data.splitter = -1;
+#endif
 
   /* Initialize picture data */
   options.picture_data.size = YAD_PICTURE_ORIG;
@@ -1536,11 +1564,13 @@ yad_create_context (void)
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
@@ -1549,11 +1579,13 @@ yad_create_context (void)
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
diff --git a/yad-dialog-code/src/paned.c b/yad-dialog-code.mod/src/paned.c
index e66d41f..24ed2ef 100644
--- a/yad-dialog-code/src/paned.c
+++ b/yad-dialog-code.mod/src/paned.c
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
@@ -122,3 +125,4 @@ paned_close_childs (void)
   shmctl (tabs[0].pid, IPC_RMID, &buf);
   shmdt (tabs);
 }
+#endif
diff --git a/yad-dialog-code.mod/src/yad b/yad-dialog-code.mod/src/yad
new file mode 100755
index 0000000..e9cdfea
Binary files /dev/null and b/yad-dialog-code.mod/src/yad differ
diff --git a/yad-dialog-code/src/yad.h b/yad-dialog-code.mod/src/yad.h
index 33dcbc7..46fab57 100644
--- a/yad-dialog-code/src/yad.h
+++ b/yad-dialog-code.mod/src/yad.h
@@ -25,7 +25,9 @@
 #include <sys/types.h>
 #include <sys/ipc.h>
 
+#ifdef GDK_WINDOWING_X11
 #include <gdk/gdkx.h>
+#endif
 
 #include <gtk/gtk.h>
 #include <glib/gi18n.h>
@@ -431,9 +433,13 @@ typedef struct {
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
@@ -451,8 +457,10 @@ typedef struct {
 #ifndef G_OS_WIN32
   guint64 parent;
   guint kill_parent;
+#ifdef GDK_WINDOWING_X11
   gboolean print_xid;
 #endif
+#endif
 } YadOptions;
 
 extern YadOptions options;
@@ -482,7 +490,7 @@ extern YadSettings settings;
 
 typedef struct {
   pid_t pid;
-  Window xid;
+  guintptr xid;
 } YadNTabs;
 
 /* pointer to shared memory for tabbed dialog */
@@ -508,16 +516,20 @@ GtkWidget *html_create_widget (GtkWidget *dlg);
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
 
 gboolean file_confirm_overwrite (GtkDialog *dlg);
+#ifdef GDK_WINDOWING_X11
 void notebook_swallow_childs (void);
 void paned_swallow_childs (void);
+#endif
 void picture_fit_to_window (void);
 
 void calendar_print_result (void);
@@ -527,8 +539,10 @@ void file_print_result (void);
 void font_print_result (void);
 void form_print_result (void);
 void list_print_result (void);
+#ifdef GDK_WINDOWING_X11
 void notebook_print_result (void);
 void paned_print_result (void);
+#endif
 void scale_print_result (void);
 void text_print_result (void);
 
@@ -540,8 +554,10 @@ gint yad_about (void);
 
 gboolean yad_send_notify (gboolean);
 
+#ifdef GDK_WINDOWING_X11
 void notebook_close_childs (void);
 void paned_close_childs (void);
+#endif
 
 void read_settings (void);
 void write_settings (void);
