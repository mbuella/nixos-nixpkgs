import ./make-test-python.nix ({ pkgs, ... } :

{
  name = "cutefish";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ mdevlamynck ];
  };

  machine = { ... }:

  {
    imports = [ ./common/user-account.nix ];
    services.xserver.enable = true;
    services.xserver.displayManager.sddm.enable = true;
    services.xserver.displayManager.defaultSession = "cutefish-xsession";
    services.xserver.desktopManager.cutefish.enable = true;
    services.xserver.displayManager.autoLogin = {
      enable = true;
      user = "alice";
    };
    virtualisation.memorySize = 1024;
  };

  enableOCR = true;

  testScript = { nodes, ... }: let
    user = nodes.machine.config.users.users.alice;
  in ''
    def assert_process_running(processes):
        for process in processes:
          machine.wait_until_succeeds("pgrep -f " + process)

    def assert_can_run_app(executable, windows, texts):
        machine.execute("su - ${user.name} -c 'DISPLAY=:0.0 XDG_RUNTIME_DIR=/run/user/${toString user.uid} " + executable + " &'")

        for window in windows:
          machine.wait_for_window(window)

        for text in texts:
          machine.wait_for_text(text)

    with subtest("Wait for login"):
        start_all()
        machine.wait_for_file("${user.home}/.Xauthority")
        machine.succeed("xauth merge ${user.home}/.Xauthority")

    with subtest("Cutefish components are running"):
        assert_process_running([
            "chotkeys",
            "cutefish-dock",
            "cutefish-filemanager",
            "cutefish-launcher",
            "cutefish-polkit-agent",
            "cutefish-powerman",
            "cutefish-session",
            "cutefish-settings-daemon",
            "cutefish-statusbar",
            "cutefish-xembedsniproxy",
            "kwin_x11"
        ])

    with subtest("Launcher can find apps"):
        assert_can_run_app("cutefish-launcher", [], ["Calculator", "File Manager", "Settings", "Terminal"])

    with subtest("Can run Settings"):
        assert_can_run_app("cutefish-settings", ["cutefish-settings"], ["Settings"])

    with subtest("Can run basic gui apps"):
        assert_can_run_app("cutefish-calculator", ["cutefish-calculator"], ["Calculator"])
        assert_can_run_app("cutefish-filemanager", ["cutefish-filemanager"], ["File Manager"])
        assert_can_run_app("cutefish-terminal", ["cutefish-terminal"], ["Terminal"])
  '';
})
