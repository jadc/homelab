{
    services.openssh = {
        enable = true;
        settings = {
            PermitRootLogin = "yes";
            ListenAddress = [ "0.0.0.0" ];
        };
    };
}
