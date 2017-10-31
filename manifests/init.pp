# installs ESA SNAP / STEP(?) processing software from
# http://step.esa.int/main/download/
class snap {
    $snap_install_dir="/opt/snap"

    # ==========================================================================
    # install 5.0.0
    # ==========================================================================
    # http://step.esa.int/downloads/5.0/installers/esa-snap_all_unix_5_0.sh
    $snap_installer = 'esa-snap_all_unix_5_0.sh'
    $snap_tmp_path  = "/tmp/${snap_installer}"
    file { "$snap_tmp_path":  # NOTE: this wastes ~500MB on the agent...
        ensure  => file,
        source  => "puppet:///modules/snap/${snap_installer}",
    }

    $varfile_path = "/tmp/snap_response.varfile"
    file { "$varfile_path":
        ensure => file,
        source => "puppet:///modules/snap/snap_5.0.0_response.varfile"
    }

    # run actual install script
    $snap5_dir="$snap_install_dir/5.0.0"
    exec {'SNAP install script':
        command     => "$snap_tmp_path -varfile $varfile_path -dir $snap5_dir > ~/SNAP_install.log",
        creates     => "$snap5_dir",
        require     => [
            File["$snap_tmp_path"],
            File["$varfile_path"],
        ],
        refreshonly => true,
    }

    $snap5_bin = "$snap5_dir/bin/snap"
    # update all modules
    exec {'SNAP update script':
        command     => "$snap5_bin --nosplash --nogui --modules --update-all",
        require     => [Exec["SNAP install script"]],
        refreshonly => true,
    }

    # set up managed symlink
    alternatives { 'snap5':
        path => "$snap5_bin",
    }
    # ==========================================================================

    # ==========================================================================
    # TODO: install & build latest SNAP using vcsrepo
    # ==========================================================================
    # https://github.com/senbox-org/snap-engine
    # https://senbox.atlassian.net/wiki/spaces/SNAP/pages/10879039/How+to+build+SNAP+from+sources
    #$snaplatest_dir="snap_install_dir/latest"
    # ==========================================================================

    # ==========================================================================
    # set up custom plugins
    # ==========================================================================
    $plugin_dir = "$snap_install_dir/plugins"
    # === c2rcc
    ## install from pre-built .nbm:
    ## NOTE: the below approach would be ideal, but unattended install is
    ##       not working in snap right now. See:
    ## http://forum.step.esa.int/t/unattended-installation-of-nbm-plugins/7520/3
    $c2rcc_installer = 's3tbx-c2rcc-0.18-SNAPSHOT.nbm'
    # $c2rcc_namespace = "org-esa-s3tbx-s3tbx-c2rcc"
    $c2rcc_dir       = "$plugin_dir/s3tbx-c2rcc"
    $c2rcc_nbm_path  = "$c2rcc_dir/target/${c2rcc_installer}"
    file { "$snap_tmp_path":  # NOTE: this wastes ~5MB on the agent.
        ensure  => file,
        source  => "puppet:///modules/snap/${c2rcc_installer}",
    }
    # exec {'c2rcc installation':
    #     command     => "$snap5_bin --nosplash --nogui --modules --install $c2rcc_tmp_path | echo $c2rcc_namespace > ~/c2rcc_install.log",
    #     creates     => "$snap_install_dir/s3tbx/modules/org-esa-s3tbx-s3tbx-c2rcc.jar",
    #     require     => [
    #         File["$c2rcc_tmp_path"],
    #         Exec['SNAP install script'],
    #     ],
    #     refreshonly => true,
    # }

    ## alternative: install plugin from source:
    # vcsrepo { "$plugin_dir/s3tbx-c2rcc":
    #     source   => 'https://github.com/bcdev/s3tbx-c2rcc.git',
    #     revision => 'master',  # aka branch
    #     ensure   => latest,
    #     provider => git,
    # }
    # TODO: install mvn
    # TODO: build with:
    # exec{"build s3tbx-c2rcc":
    #     comand => "mvn clean package",
    #     cwd    => "$c2rcc_dir"
    # }
    # ==========================================================================
}
