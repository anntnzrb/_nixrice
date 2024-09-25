{
  config.programs.firefox.profiles.default.settings = {
    "browser.fullscreen.autohide" = true;
    "browser.sessionstore.interval" = 45; # save session every X seconds
    "browser.startup.homepage" = "about:blank";
    "browser.startup.page" = 3; # continue where left off
    "browser.urlbar.clickSelectsAll" = true;

    "identity.fxaccounts.toolbar.defaultVisible" = false;

    "extensions.checkCompatibility" = false;
    "extensions.formautofill.addresses.enabled" = false;
    "extensions.formautofill.available" = "off";
    "extensions.formautofill.creditCards.available" = false;
    "extensions.formautofill.creditCards.enabled" = false;
    "extensions.formautofill.heuristics.enabled" = false;
    "extensions.getAddons.showPane" = false;
    "extensions.htmlaboutaddons.recommendations.enabled" = false;
    "extensions.pocket.enabled" = false;
    "extensions.pocket.site" = "";

    "services.sync.engine.addons" = false;
    "services.sync.engine.creditcards" = false;
    "services.sync.engine.passwords" = false;

    "browser.ping-centre.telemetry" = false;
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.bhrPing.enabled" = false;
    "toolkit.telemetry.coverage.opt-out" = true;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.firstShutdownPing.enabled" = false;
    "toolkit.telemetry.newProfilePing.enabled" = false;
    "toolkit.telemetry.server" = "data:,";
    "toolkit.telemetry.shutdownPingSender.enabled" = false;
    "toolkit.telemetry.unified" = false;
    "toolkit.telemetry.updatePing.enabled" = false;

    # misc
    "general.smoothScroll" = true;
    "network.prefetch-next" = false;
    "layout.spellcheckDefault" = 2;
  };
}
