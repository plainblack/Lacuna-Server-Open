#!/data/apps/bin/perl
use strict;
use warnings;
use 5.010;

use POSIX ();
BEGIN {
    fork && POSIX::_exit(0);
    POSIX::setsid();
    fork && POSIX::_exit(0);
}

use Config::JSON;
use Symbol;
use IPC::Open3;
use Net::Amazon::S3;
use DateTime;
use DateTime::Format::HTTP;
use Path::Class::Dir;
use Git::Wrapper;
$ENV{PATH} = '/data/apps/bin:' . $ENV{PATH};
#open STDERR, '>>', '/tmp/lacuna-deploy.log';

my $config = Config::JSON->new('/data/Lacuna-Server/etc/lacuna.conf');
my $s3 = Net::Amazon::S3->new(
    aws_access_key_id     => $config->get('access_key'),
    aws_secret_access_key => $config->get('secret_key'),
    retry                 => 1,
);
my %types = (
    css     => 'text/css',
    cur     => 'image/x-win-bitmap',
    gif     => 'image/png',
    html    => 'text/html',
    jpg     => 'image/jpeg',
    js      => 'text/javascript',
    json    => 'application/json',
    png     => 'image/png',
    txt     => 'text/plain',
);

run(@ARGV);

sub run {
    my ($repo, $branch) = @_;

    my $repo_config = $config->get("repo/$repo");

    return
        unless $repo_config;

    my $branch_config = $repo_config->{branch}{$branch};
    return
        unless $branch_config;

    my $dir = Path::Class::Dir->new($repo_config->{path});
    my $git = Git::Wrapper->new($repo_config->{path});
    $git->fetch;
    $git->checkout($branch);
    my ($old_rev) = $git->rev_parse('HEAD');
    $git->pull;
    my @updated_files = $git->diff({name_only => 1}, $old_rev, 'HEAD');

    given ($repo) {
        when ('Lacuna-Web-Client') {
            my $bucket = $branch_config->{bucket};
            my $s3bucket = $s3->bucket($bucket)
                or die $s3->err . ": " . $s3->errstr;
            my ($new_rev) = $git->rev_parse({short => 1}, 'HEAD');
            my $url_root = $branch_config->{url_root};
            my $license_text = sprintf <<'END_TEXT', (localtime)[5] + 1900, $new_rev;
/*
Copyright (c) %s, Lacuna Expanse Corp. All rights reserved.
Code licensed under the BSD License:
http://github.com/plainblack/Lacuna-Web-Client/blob/master/LICENSE
Built from: http://github.com/plainblack/Lacuna-Web-Client/commit/%s
*/
END_TEXT
            if (-f $dir->file('package.json'))
            {
                # new gulp-based client.
                chdir($repo_config->{path});
                system("npm install");
                system("gulp");

                my $lacuna_dir = $dir->subdir('lacuna');
                $lacuna_dir->recurse(
                    callback => sub {
                        my $file = shift;
                        return unless -f $file;
                        my ($ext) = $file =~ /\.(css|js)$/;
                        my $type = $types{$ext} || 'text/plain';
                        my $s3path = "code/$new_rev/" . $file->relative($dir);

                        my $content = $license_text . $file->slurp;
                        $content = cmd_pipe($content, 'gzip', '-9');

                        $s3bucket->add_key(
                            $s3path,
                            $final,
                            {
                                'Content-Type'      => $type,
                                'Content-Encoding'  => 'gzip',
                                'Expires'           => DateTime::Format::HTTP->format_datetime(DateTime->now->add(years=>5)),
                                'Cache-Control'     => 'max-age=290304000, public',
                                acl_short           => 'public-read',
                            },
                            ) or die $s3->err . ": " . $s3->errstr;
                    });
            }
            else
            {
                # older YUI-based client.

                $dir->recurse(callback => sub {
                    my $file = shift;
                    return
                        unless -f $file;
                    my ($ext) = $file =~ /\.(css|js)$/;
                    return
                        unless $ext;

                    my $type = $types{$ext} || 'text/plain';
                    my $s3path = "code/$new_rev/" . $file->relative($dir);

                    my $content = $file->slurp;

                    $content =~ s{^/\*\*\s*BUILD.*?^(.*?)^/\*\*\s*END.*?^}{$1}msxg;
                    $content =~ s{^/\*\*\s*DEBUG.*?^(.*?)^/\*\*\s*END.*?^}{}msxg;
                    $content =~ s{\*\*\s*CODEROOT}{$url_root/code/$new_rev/}msxg;
                    #if ($ext eq 'css') {
                    #    $content =~ s{\b(assets/)}{$url_root/$1}msxg;
                    #}

                    my $min = cmd_pipe($content, 'java', '-jar', $config->get('yuicompressor'), '--type', $ext);

                    my $final = $license_text . $min;

                    $final = cmd_pipe($final, 'gzip', '-9');

                    $s3bucket->add_key(
                        $s3path,
                        $final,
                        {
                            'Content-Type'      => $type,
                            'Content-Encoding'  => 'gzip',
                            'Expires'           => DateTime::Format::HTTP->format_datetime(DateTime->now->add(years=>5)),
                            'Cache-Control'     => 'max-age=290304000, public',
                            acl_short           => 'public-read',
                        },
                    ) or die $s3->err . ": " . $s3->errstr;
                });
            }

            my $server_git = Git::Wrapper->new('/data/Lacuna-Server/');
            $server_git->pull;
            my $index_file = '/data/Lacuna-Server/var/www/public/index.html';
            my $index = do {
                open my $fh, '<', $index_file;
                local $/;
                <$fh>;
            };
            $index =~ s{((?:href|src)=")[^"]+(/(?:load\.(?:min\.)?js|styles\.(?:min\.)?css)")}{$1$url_root/code/$new_rev$2}msxg;
            open my $fh, '>', $index_file;
            print {$fh} $index;
            close $fh;
            $server_git->commit({all => 1, message => 'updating for new ui code'});
            $server_git->push('origin', $branch);

            my $allfiles = $s3bucket->list_all({prefix => 'code/'});
            for my $key (@{ $allfiles->{keys} }) {
                my $file = $key->{key};
                if ($file =~ m{^code/$new_rev/}) {
                    next;
                }
                $s3bucket->delete_key($file);
            }
        }
        when ('Lacuna-Server') {
            # pull already done locally
        }
        when ('Lacuna-Assets') {
            my $bucket = $branch_config->{bucket};
            my $s3bucket = $s3->bucket($bucket);
            for my $file (@updated_files) {
                my $local_file = $dir->file($file);
                next
                    unless $local_file && -f $local_file;

                my ($ext) = $file =~ /\.([^.]+)$/;

                my $type = $types{$ext} || 'text/plain';

                my $s3path = "assets/$file";

                $s3bucket->add_key_filename(
                    $s3path,
                    $local_file->stringify,
                    {
                        'Content-Type'      => $type,
                        'Expires'           => DateTime::Format::HTTP->format_datetime(DateTime->now->add(years=>5)),
                        'Cache-Control'     => 'max-age=290304000, public',
                        acl_short           => 'public-read',
                    },
                ) or die $s3->err . ": " . $s3->errstr;
            }
        }
    }
}

sub cmd_pipe {
    my ($content, @cmd) = @_;
    my ($wtr, $rdr);
    my $err = Symbol::gensym();
    my $pid = IPC::Open3::open3($wtr, $rdr, $err, @cmd);
    print {$wtr} $content;
    close $wtr;
    my $out = do {local $/; <$rdr>};
    chomp (my @err = <$err>);
    waitpid $pid, 0;
    return $out;
}

