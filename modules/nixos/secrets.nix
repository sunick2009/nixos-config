{ config, pkgs, agenix, secrets, ... }:

let user = "susu"; in
{
  age.identityPaths = [
    "/home/${user}/.ssh/id_ed25519_agenix"
  ];

  age.secrets."atuin-sync-env" = {
    # Use local secrets repo file directly to ensure it's available during activation
    file = "${secrets}/atuin-sync.env.age";
    mode = "600";
    owner = user;
    group = "wheel";
  };

  age.secrets."atuin-key" = {
    file = "${secrets}/atuin.key.age";
    mode = "600";
    owner = user;
    group = "wheel";
  };

  # Your secrets go here
  #
  # Note: the installWithSecrets command you ran to boostrap the machine actually copies over
  #       a Github key pair. However, if you want to store the keypair in your nix-secrets repo
  #       instead, you can reference the age files and specify the symlink path here. Then add your
  #       public key in shared/files.nix.
  #
  #       If you change the key name, you'll need to update the SSH configuration in shared/home-manager.nix
  #       so Github reads it correctly.

  #
  # age.secrets."github-ssh-key" = {
  #   symlink = false;
  #   path = "/home/${user}/.ssh/id_github";
  #   file =  "${secrets}/github-ssh-key.age";
  #   mode = "600";
  #   owner = "${user}";
  #   group = "wheel";
  # };

}
