{ inputs, ... }:

{
    homelab = {
        system = {
            superuser = {
                hashedPasswordFile = "${inputs.secrets}/passwd.hash";
            };
            timeZone = "America/Edmonton";
            locale = "en_CA.UTF-8";
        };
    };
}
