#!/usr/bin/perl
sub reformat($);
sub read_mpf;
#   mk_sdf   : Standard Delay Formatt file generator

#   Copyright (C) 1999-2007 Free Model Foundry; http://www.FreeModelFoundry.com
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License version 2 as
#   published by the Free Software Foundation.
#
#   Author  : A. Savic, R. Munden
#   Date    : 20070709
#   Version : 4.1.2

#   Revision history:
#   4.0: 20070213 - HDL Design House
#      o Rewrite
#   4.1: 20070430 - RGM
#      o restored command line arguments, made default temp file location /tmp
#   4.1.1: 20070707 - RGM
#      o made first command line arg override "vhdl_file"
#   4.1.2: 20070709 - RGM
#      o return support for timingfile_dir

#################################################################
# command line arguments:
# ARGV[0] - name of VHDL netlist
# or
# netlist_name
# netlist_dir
# rfv
# vendor
# 

# global variables:
# %component_list - list of instance names by component name
# %instance_isin - list architectures by instances contained therein
# %instance_comp - list of component names by instance name
# %comp_lib - library each component (by name) is configured to
# @instance_list - array of all instance names in design in order found
$version = '4.1';
$design_name = '';
$diags = 'off';
# INPUT files
$CMD = 'mk_sdf.cmd';
$VHD = '';  #  name of VHDL netlist
$sdf_file = '';   # name of SDF file
$RFV = '/tmp/wrap.vhd'; # output file $RFV is reformatted VHDL

$current_architecture = '';
#########################################################################
## read mk_sdf.cmd file
## get VHD file name
## open sdf file
#########################################################################
read_cmd_file();
get_names();
begin_sdf();
$VHDpath ="/$models_dir/$VHD";
$VHDpath =~ s/\s//;
## create $RFV file that is reformated VHDL file for component instance
&reformat($VHDpath);
## find architecture for VHDL file and components it has
%keywords = (architecture_arr() => 1,
             component()        => 1,
             timingmodel()      => 1);
## search all instances
## find for instances timing files and paths for them to write sdf file
## close sdf file
&search;
&build_paths;
&close_sdf;

print "$time\n";
##################################################################
## open $RFV file and find for architecture for instance;
## importante when searching instances
##  in next component_name.vhd file
##################################################################
sub architecture_arr {
    open RFV, $RFV;
    @lines = <RFV>;
    close RFV;
    foreach $line (@lines) {
        if($line =~ /architecture/ ){
            @words = split / /, $line;
            $current_architecture = $words[3];
            push (@arch_array, $current_architecture);
            }
        }
}
##################################################################
## open $RFV file and find for component instance, component name
## ( component component_name (is)
##      generic()
##      port()
##  )
##################################################################
sub component {
    open RFV, $RFV;
    @lines = <RFV>;
    close RFV;
    foreach $line (@lines) {
        @words = split / /, $line;
        foreach $word(@words) {
            ##  find instances of components in opened vhd file
            ##  no metter what syntax of vhd file is
            if( $words[0] =~ /component/  &&
              ($words[2] =~ /port|generic/ || $words[2] =~ /is/ ) )
            {
                $arch_list{$current_architecture} =
                $arch_list{$current_architecture} . " " . $words[1];
                ## if doesn't exist value in %component_list give it value =" "
                unless($component_list{$words[1]}){ $component_list{$words[1]} = " ";}
            }
        }
    }
}
##################################################################
## open $RFV file and find for component instance timing model
## ( timingmodel => "timingmodel_name")
##################################################################
sub timingmodel {

    open RFV,$RFV;
    @lines = <RFV>;
    close RFV;

    foreach $line (@lines) {
        if ($line =~ /generic map/){
            @words = split / /, $line;
            if ($line=~ /timingmodel => \"(.+)\"/ ) {
                $model = $1;
                $model_name{$words[0]} = $model;
            }
        }
    }
}
##################################################################
## open sdf file and write a header init
##################################################################
sub begin_sdf
{
    if ( $diags ne off ) {
        print "writing SDF boilerplate\n";
    }
    ## remember the path for vhd file
    $tmp = "/$models_dir/$sdf_file";
     ## write sdf file in folder where vhd file is
    print " SDF: $tmp \n";

    $time = localtime;
    if (open(SDF, ">$tmp") !=1) { die "can't open $tmp $!\n";}
    print "Opening $tmp\n";
    print SDF "(DELAYFILE\n";
    print SDF " (SDFVERSION \"2.1\")\n";
    print SDF " (DESIGN \"$design_name\")\n";
    print SDF " (DATE \"$time\")\n";
    print SDF " (VENDOR \"Free Model Foundry\")\n";
    print SDF " (PROGRAM \"SDF timing utility(tm)\")\n";
    print SDF " (VERSION \"$version\")\n";
    print SDF " (DIVIDER /)\n";
    print SDF " (VOLTAGE)\n";
    print SDF " (PROCESS)\n";
    print SDF " (TEMPERATURE)\n";
    print SDF " (TIMESCALE 1ns)\n";
}

##################################################################
## for each instance in array instance_list
## find timing_file and remember is timing file found or not
## call add_timing() procedure to write sdf file for each instance
##################################################################
sub build_paths {
    foreach $instance_list (@instance_list) {
        @instance = $instance_list;
        foreach $instance (@instance){
        ##########################################################
        ## if not found timing file, open VHDL file instance and
        ## find all instances and components in it
        ## as architecture for them and timing models
        ##########################################################
            if(defined $ffail{$instance}) {
                $VHDpath = $ffail{$instance};
                &reformat($VHDpath);
                &architecture_arr;
                &component;
                &timingmodel;
                &search;
            }
            if ($ffound{$instance}){
                if ( $diags ne off ){ print "working on $instance \n";}
                if ($model_name{$instance} ne ""){
                    ## if Timing Model exist for instance
                    print SDF " (CELL\n";
                    print SDF " (CELLTYPE \"$instance_comp{$instance}\")\n";
                    $inst = $instance;
                    $pathinstance{$inst}=$instance;
                    $full_inst =$instance;
                    ##################################################################
                    ## instance has timing file
                    ## search back all previous instances,i.e. find path of instance
                    ## till the beginning instance when start search for all instances
                    ##################################################################
                    while ( $component_list{$instance_isin{$inst}} ) {
                        $path_1 = "$full_inst/$instance" ;
                        if($full_inst=~ $instance){
                            $path_1 = $full_inst;
                         }
                        $full_inst = "$component_list{$instance_isin{$inst}}/$inst";
                        $full_inst =~ s/\s+//;
                        $pathinstance{$instance}=$full_inst."/"."$pathinstance{$instance}";
                        ## new instance
                        $inst = $component_list{$instance_isin{$inst}};
                        $inst =~ s/\s+//;
                    }
                    ## delete duplicate names in $pathinstance{$instance}
                    $str= $pathinstance{$instance};
                    @array= split ("/",$str);
                    @unique =();
                    %seen = ();
                    foreach $element(@array) {
                        next if $seen{$element}++ ;
                        if ($array[0]=~ $element){
                            push @unique, $element;
                        }else{
                        push @unique,"/$element";}
                    }
                    ## string $str1 has no white spaces
                    $str1= "@unique";
                    $str1=~ s/\s+//g;
                    #############################################
                    ## call the procedure to write in sdf file
                    ## timing constraint values for instance
                    #############################################
                    print SDF " (INSTANCE   $str1) \n";
                    &add_timing($str1,$instance);
                }
            }
        }
    }
}
##################################################################
## write sdf file
## arguments: the instance path
##           and instance which timing data is writing in sdf file
##################################################################
sub add_timing($,$$)
{
    $instance_path = shift;
    $timing_found = "false";
    $part_found = "false";
    unless ($timing_file{$instance})
    {
        print "path to $timing_file{$instance} not found\n";
        exit;
    }

    ## open timing file exist
    if (open(TF, "<$timing_file{$instance}") !=1)
       { warn "can't open $timing_file{$instance}\n"; }
    if ( $diags ne off ) {
        print "reading $timing_file{$instance}\n";
    }
    $section_found = "false";
    while (<TF>)
    {
        ## find TimingModel name of instance in .ftm file
        ## write timing constraints values
        next unless (/$model_name{$instance}/i || ($part_found eq "true"));
        $part_found = "true";
        if ( $diags ne off ) {
            print "found entry for $model_name{$instance}\n";
        }
        next unless (/<timing>/i || ($timing_found eq "true"));
        $timing_found = "true";
        next if (/<timing>/i);
        if (/<\/timing>/i)
        {
            print SDF " )\n";
            $timing_found = "false";
            $part_found = "false";
            $section_found = "true";
            last;
        } else {
            ################################################
            ## write in sdf file timing constraint values
            ## for each instance
            ## no metter what syntax of ftm file is
            ################################################
            if (/%LABEL%/){
                $_ =~ s/%LABEL%/$instance_path/;
            }elsif (/dut/) {
                $_ =~ s/dut/$instance_path/;
            }
            print SDF $_;
        }
    }
    unless ($section_found eq "true") {
        print "$model_name not found\n";
    }
}
##################################################################
## close sdf file
##################################################################
sub close_sdf
{
    print SDF ")\n";
    print "closing SDF file $tmp \n";
    print " \n";
    close(SDF);
}
##################################################################
# read mk_sdf.cmd file
## get path for ftm file
## get path for vhd file to open
## get path for RFV file to write to reformated VHDL
##################################################################
sub read_cmd_file {
    if (open(CMD, $CMD) !=1) { die "can't open $CMD\n"; }
    while (<CMD>) {
        chop;
        @fields = '';
        @fields = split;
        unless ($fields[0] =~ /#/) {
            if ($fields[0] =~ /SET/) {
                if ($fields[1] =~ /use_global_timing_dir/) {$gtd = $fields[2]}
                if ($fields[1] =~ /modelfile_dir/) {$models_dir = $fields[2]}
                if ($fields[1] =~ /timingfile_dir/) {$timing_dir = $fields[2]}
                if ($fields[1] =~ /vhdl_file/) {$VHD = $fields[2]}
                if ($fields[1] =~ /sdffile_suffix/) {$suffix = $fields[2]}
                if ($fields[1] =~ /time_scale/) {$timing_scale = $fields[2]}
                if ($fields[1] =~ /vendor/) {$vendor = $fields[2]}
                if ($fields[1] =~ /diagnostics/) {$diags = $fields[2]}
                if ($fields[1] =~ /RFV/) {$RFV = $fields[2]}

            }
        }
    }
    if ( ($diags ne off)and((@ARGV+1)!= 0) ) {
        print "\nmk_sdf diagnostics on\n\n";
        print "vhdl_file $VHD\n";
        print "sdffile_suffix $suffix\n";
        print "use_global_timing_dir $gtd\n";
        print "modelfile_dir $models_dir\n";
        print "timingfile_dir $timing_dir\n";
        print "time_scale $timing_scale\n";
        print "vendor $vendor\n";
        print "RFV $RFV\n\n";
    }
}
##################################################################
##  if user launch script with arguments, take their values
## and over ride values set in command file
##################################################################
sub get_names {
   # 21.02 2007 with or without using arguments
   ##  if $vendor read project file or find model paths by user envr.
   $user_environment = "false";
   if ($gtd =~ /false/) {
       if ($vendor =~ /modeltech/i) { &read_mpf; }
       if ($vendor =~ /cadence/i) { &read_ncvhdl; }
   }
#    if ($vendor =~ /user_environment/i) { $user_environment = "true"; }

    @name = split(/\./,$VHD);
    $design_name = $name[0];
    for ($argum = 0;$argum < 3; $argum++){
      ### if path for model file is set, use it instead of path from .cmd file
      ### if design name is set as name.vhd OK, else if it's path then split it
      ### if path for RFV file is set use it instead of path from .cmd file
        if ($ARGV[$argum*2] =~ /netlist_name/i){
            if ($ARGV[$argum*2+1] ne "") {
                $design_name = $ARGV[$argum*2+1];
                $VHD = "$ARGV[$argum*2+1].vhd";
            }
        }elsif($ARGV[$argum*2] =~ /netlist_dir/i){
            if ($ARGV[$argum*2+1] ne "" ){
                $models_dir= $ARGV[$argum*2+1];
            }
        }elsif($ARGV[$argum*2] =~ /rfv/i) {
            if ($ARGV[$argum*2+1] ne ""){
              $RFV = $ARGV[$argum*2+1];
            }
        }elsif ( $ARGV[$argum*2] =~ /vendor/i){
            if ($ARGV[$argum*2+1] ne ""){
                if ($ARGV[$argum*2+1] =~ /modeltech/i) {
                    &read_mpf;
                    print "Using ModelSim environment\n";
                     $user_environment = "false"; }
                if ($ARGV[$argum*2+1] =~ /cadence/i) {
                    &read_ncvhdl;
                    print "Using NCSim environment\n";
                    $user_environment = "false"; }
#                 if ($ARGV[$argum*2+1] =~ /user_environment/i){
#                     $user_environment = "true"; }
            }
        }elsif ( $ARGV[$argum*2] =~ /time_scale/i){
            if ($ARGV[$argum*2+1] ne ""){
                $timing_scale = $ARGV[$argum*2+1];
            }
        }elsif ( $ARGV[$argum*2] =~ /use_global_timing_dir/i ){
            if ($ARGV[$argum*2+1] ne ""){
                $gtd = $ARGV[$argum*2+1];
            }
        }elsif ( $ARGV[$argum*2] =~ /timingfile_dir/i ){
            if ($ARGV[$argum*2+1] ne ""){
                $timing_dir = $ARGV[$argum*2+1];
            }
        }elsif ($ARGV[0]) {
            $VHD = "$ARGV[0]";
        }
    }
    @name = split(/\./,$VHD);
    $sdf_file = $name[0] . $suffix;

    if ( $diags ne off ) {
        print "sdf_file : $sdf_file  \n";
        print "design name is $design_name\n";
        print "VHDL file name is $VHD\n";
        print "modelfile_dir is $models_dir\n";
        print "time_scale $timing_scale\n";
        print "use_global_timing_dir $gtd\n";
        print "RFV temporary file is $RFV\n\n";
    }
}
##################################################################
# reformat netlist
##################################################################
sub reformat($) {
    $entfound = false;
    if (open (VHD, $VHDpath) !=1) { die "can't open VHD $VHDpath \n";}
    if (open (OUT, "> $RFV") !=1) { die "can't open RFV $RFV\n"; }
    while (<VHD>) {
        if (/^--|library|package/i) { next }
        if (/--/) {              # strip embeded comments
            @line = split("--");
            $_ = $line[0];
        }
        s/:/ : /g;
        s/;/ ;/g;
        s/\s+/ /g;      # reduces spaces and tabs
        s/^\s//g;       # no leading spaces
        if (/entity/i) {
            $entfound = "true";
        }
        chomp;
        if ( $entfound eq true ) {
            print OUT lc($_);
            if (/;|is|begin/i) { print OUT "\n"; }
        }
    }

    close OUT;
    if ( $diags ne off ) {
        print "reformatted netlist $VHDpath written to $RFV \n\n";
    }
}
#########################################################################
## find all instances in one level of hierarchy if vhd and ftm files exist
## if vhd file doesn't exist print message
## if vhd file exist, check if ftm file exist;
## if ftm file doesn't exist for that instance  search for new instances
## in it's component_name.vhd (next level of searching)
#########################################################################
sub search{
open INPUT, $RFV;
@lines = <INPUT>;
close INPUT;
    foreach $line(@lines) {
        @words = split / /, $line;
        foreach $word (@words) {
            $keywords{$word} == "1" && do { &$word(@words);};
            if ($component_list{$word}) {
                (($line =~ /(.+) : $word/) and
                     ($1 !~ /for/) ) and do {
                     # instantiation found
                        $component_list{$word} = $component_list{$word} . $1;
                        push (@instance_list, $1);
                        $instance_name = $1;
                        $instance_comp{$1} = $word;  # component_name
                        # component architecture is the same as the name of component
                        $instance_isin{$1} = $current_architecture;
                        if ( $diags ne off ) {
                            print "reading instance $instance_name: $word in $current_architecture\n";
                        }
#                       21.02.2007 working in user environment or NCSim or ModelSim envr.
#                         if ($user_environment =~ /true/){
                        if ($gtd =~ /true/) {
                            &find_files1($instance_name);
                        }elsif ($user_environment =~ /false/){
                            &find_files2($instance_name);
                        }
                };
                $line =~ /for all : $word use entity (.+)/ and do {
                    @config = split(/\./, $1);
                    $comp_lib{$word} = $config[0];};
            }
        }
    }
    if ( $diags ne off ) {
        print "finished with netlist\n\n";
    }
}
#########################################################################
## check if timing file for instance exist
## if timing file doesn't exist search deeper on next level of hierarchy
## research component_name.vhd file
## no matter if timing file exist or not, it's created %ffail and %ffound
## %ffail=(instance => $timing_file) and %ffound{$instance}
##-----------------------------------------------------------------------
## recognize user environment and get models path
#########################################################################

sub find_files1($) {

    $inst = shift;
    $path1 = "$lib_path{$comp_lib{$instance_comp{$inst}}}/$timing_dir";
    $path2 = "/$models_dir";
#    $path3 = "/$timing_dir";

    $model_file = "$path2/$instance_comp{$inst}.vhd";
    $timing_file{$inst} = "$path1/$instance_comp{$inst}.ftm";
#    $timing_file{$inst} = "$path3/$instance_comp{$inst}.ftm";
    $timing_file{$inst} =~ s/\s//;
    $model_file =~ s/\s//;
    if(-e $model_file) {

        print "File  $model_file exist. \n";
        if (-e $timing_file{$inst}) {
            print "$timing_file{$inst} exist!\n";
            $ffound{$inst}  = $model_file;
        }else{
            if ( $diags ne off ) {
                print "$timing_file{$inst} not found!\n";
            }
            $ffail{$inst} = $model_file;
        }
        ## remember the name of component with instance in it
        ##  that we searching for timing file
        ## no matter if timing file exist or not
        $component_list{$inst}= $instance_comp{$inst};

    }else { print "File $model_file not found \n"; }
   }
##################################################################
## for  ModelSim or NCSim environment
## when reading project file to get models path
##################################################################
sub find_files2($) {
    $inst = shift;
    foreach $model_el (@model_array) {
        if ($model_el =~ "$instance_comp{$inst}.vhd") {
              $model_file = $model_el;
              $model_file =~ s/\s//;
              $timing_file{$inst} = $model_el;
              $timing_file{$inst} =~ s/.vhd$//;
              $timing_file{$inst} =~ s/\s//;
              $timing_file{$inst} ="$timing_file{$inst}.ftm";
              $timing_file{$inst} =~ s/\s//;
        }
    }
    if(-e $model_file) {
        print "File  $model_file exist. \n";
        if (-e $timing_file{$inst}) {
            print "$timing_file{$inst} exist!\n";
            $ffound{$inst}  = $model_file;
        }else{
            if ( $diags ne off ) {
                print "$timing_file{$inst} not found!\n";
            }
            $ffail{$inst} = $model_file;
        }
        $component_list{$inst}= $instance_comp{$inst};
    }else { print "File $model_file not found \n"; }
}
#########################################################################
## reading  project .mpf file if ModelSim environment
#########################################################################
sub read_mpf {
    $tmp_inst = shift;
    $tmp_dir= "/$models_dir";
    opendir(DIR, $tmp_dir);
    @files = readdir(DIR);
    foreach $file(@files){
       if ( $file =~ /\.mpf$/i){
          $found_mpf = $file; }
    }
    close DIR;

    $tmp_mpf = "$tmp_dir/$found_mpf";
    if (open(MPF, "< $tmp_mpf") !=1 ) { die "can't open .mpf file $tmp_mpf \n";}
    @lines = <MPF>;
    close MPF;
    $i=0;
    foreach $line (@lines) {
        if ($line =~ "Project_File_"){
            @words = split / /, $line;
            if ( ($words[1]== "=" ) and ($words[2]=~ ".vhd") ) {
                if ($words[2] =~ "/$design_name.vhd") {next;##skip design file
                }else{
                    $model_array[$i] = $words[2];
                    $model_array[$i] =~ s/\s//;
                    $i++;
                }
            }
        }
    }
}
#############################################################################
## if NCSim environment, read ncvhdl.log for getting components path
#############################################################################
sub read_ncvhdl {
    $tmp_inst = shift;
    $tmp_dir= "/$models_dir";
    opendir(DIR, $tmp_dir);
    @files = readdir(DIR);
    foreach $file(@files){
       if ( $file =~ /ncvhdl.log/i){
          $found_nclog = $file; }
    }
    close DIR;
    print "DIR: $tmp_dir  \n";
    $tmp_ncvhdl= "$tmp_dir/$found_nclog";
    if (open(NCLOG, "< $tmp_ncvhdl") !=1 ) { die "can't open ncvhdl.log file $tmp_ncvhdl  \n";}
    @lines = <NCLOG>;
    close NCLOG;
    $i =0;
    foreach $line (@lines) {
        if ($line =~ /(\w)+\.vhd/){
            if ($model_el =~ "/$design_name.vhd") {next;
            }else{
                $model_array[$i] = $tmp_dir.$&;## correct path???
                print "MODEL array in ncvhdl: $model_array[$i],$i  \n";
                $i++;
            }
        }
    }
}
