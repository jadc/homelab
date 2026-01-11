{
    services.openssh = {
        enable = true;
        settings = {
            PermitRootLogin = "yes";
            listenAddresses = [
                { addr = "0.0.0.0"; port = 22; }
            ];
        };
    };
}
