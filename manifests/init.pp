# installs ESA SNAP / STEP(?) processing software from
# http://step.esa.int/main/download/
class snap (
    $snap_base_install_dir = "/opt/snap",
    $version = "5.0",  # version in dot-notation
    $default_version = "5.0",  # version ln from /opt/snap/default & alt as snap
    ){
    $version_ = regsubst($version, '\.', '_', 'G')  # underscore notation eg 5_0
    $snap_v_dir = "${snap_base_install_dir}_${version_}"

    # ==========================================================================
    # install given version
    # ==========================================================================
    # http://step.esa.int/downloads/5.0/installers/esa-snap_all_unix_5_0.sh
    $snap_installer = "esa-snap_all_unix_${version_}.sh"
    $installer_src = "http://step.esa.int/downloads/5.0/installers/esa-snap_all_unix_${version_}.sh"
    $snap_tmp_path  = "/tmp/${snap_installer}"
    file { "$snap_tmp_path":  # NOTE: this wastes ~500MB on the agent...
        ensure  => file,
        source  => $installer_src,
        mode    => '0750'
    }

    $varfile_path = "/tmp/snap_response_${version_}.varfile"
    $varfile_src = "puppet:///modules/snap/snap_${version}.0_response.varfile"
    file { "$varfile_path":
        ensure => file,
        source => $varfile_src
    }

    # === run actual install script
    exec {'SNAP install script':
        command     => "$snap_tmp_path -q -varfile $varfile_path -dir $snap_v_dir > ~/SNAP_install.log",
        creates     => "$snap_v_dir",
        subscribe     => [
            File["$snap_tmp_path"],
            File["$varfile_path"],
        ],
        refreshonly => true,
    }

    $snap_v_bin = "$snap_v_dir/bin/snap"
    # === update all modules
    exec {'SNAP update script':
        command     => "$snap_v_bin --nosplash --nogui --modules --update-all",
        subscribe     => [Exec["SNAP install script"]],
        refreshonly => true,
    }

    # === set up managed symlinks
    ## these two don't work:
    # alternatives { 'snap5':
    #     path => "$snap_v_bin",
    # }
    #
    # $gpt5_bin = "$snap_v_dir/bin/gpt"
    # alternatives { 'gpt5':
    #     path => "$gpt5_bin",
    # }
    ## maybe they should be done like below???
    # alternative_entry { "$snap_v_bin":
    #     ensure => present,
    #     altname => 'snap5',
    #     priority => 10,
    #     path => ,
    # }
    ## not sure https://forge.puppet.com/puppet/alternatives
    # ==========================================================================

    # ==========================================================================
    # TODO: install & build latest SNAP using vcsrepo
    # ==========================================================================
    # https://github.com/senbox-org/snap-engine
    # https://senbox.atlassian.net/wiki/spaces/SNAP/pages/10879039/How+to+build+SNAP+from+sources
    #$snaplatest_dir="${snap_base_install_dir}_latest"
    # ==========================================================================

    # ==========================================================================
    # set up custom plugins
    # ==========================================================================
    # $plugin_dir = "$snap_v_dir/plugins"
    # # === c2rcc
    # ## install from pre-built .nbm:
    # ## NOTE: the below approach would be ideal, but unattended install is
    # ##       not working in snap right now. See:
    # ## http://forum.step.esa.int/t/unattended-installation-of-nbm-plugins/7520/3
    # $c2rcc_installer = 's3tbx-c2rcc-0.18-SNAPSHOT.nbm'
    # # $c2rcc_namespace = "org-esa-s3tbx-s3tbx-c2rcc"
    # $c2rcc_dir       = "$plugin_dir/s3tbx-c2rcc"
    # $c2rcc_nbm_path  = "$c2rcc_dir/target/${c2rcc_installer}"
    # file { "$snap_tmp_path":  # NOTE: this wastes ~5MB on the agent.
    #     ensure  => file,
    #     source  => "puppet:///modules/snap/${c2rcc_installer}",
    # }
    # exec {'c2rcc installation':
    #     command     => "$snap_v_bin --nosplash --nogui --modules --install $c2rcc_tmp_path | echo $c2rcc_namespace > ~/c2rcc_install.log",
    #     creates     => "$snap_v_dir/s3tbx/modules/org-esa-s3tbx-s3tbx-c2rcc.jar",
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
