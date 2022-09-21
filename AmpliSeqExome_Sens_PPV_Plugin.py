#!/usr/bin/env python

# Copyright (C) 2019 Thermo Fisher Scientific. All Rights Reserved

import glob
import sys
import subprocess
import json
import os
import re
import shutil
from ion.plugin import *
from django.utils.functional import cached_property
from django.conf import settings
from django.template.loader import render_to_string




class AmpliSeqExome_Sens_PPV_Plugin(IonPlugin):
  version = '1.0.0.0'
  runtypes = [RunType.FULLCHIP, RunType.THUMB, RunType.COMPOSITE]

  # a simple cached version of the start plugin property
  @cached_property
  def startplugin_json(self):
    return self.startplugin

  def launch(self,data=None):
    net_location = self.startplugin_json['runinfo']['net_location']
    plugin_result_dir = self.startplugin_json['runinfo']['plugin'].get('results_dir')#
    tvc_dir  = self.startplugin_json['pluginconfig'].get('variant_caller_path')
    tvc_name = os.path.basename(tvc_dir.rstrip('/')) # 

    abs_path = os.path.abspath(__file__)
    this_dir = os.path.dirname(abs_path)#
    
    print "input variantCaller dir is: %s" % (tvc_dir)
    print "output dir is: %s" % (plugin_result_dir)
    fa = "/results/referenceLibrary/tmap-f3/hg19/hg19.fasta"
    cmd = "perl %s/AmpliSeqExome_Sens_PPV_Plugin_pipeline.pl %s %s %s" % (this_dir,tvc_dir,fa,plugin_result_dir)
    print "cmd is: %s" % (cmd)
    os.system(cmd)

    url_root = self.startplugin_json['runinfo']['url_root']
    file_path = "%s/plugin_out/%s" % (url_root,os.path.basename(plugin_result_dir))
    print(file_path)
    
    with open("AmpliSeqExome_Sens_PPV_Plugin.html","w") as f:
      val = "variantCaller Result: %s" % (tvc_name)
      f.write("<html><body>" + val + "<br>")
      full_ana_dir = os.path.join('/results/analysis',file_path)
      f.write(full_ana_dir)
      print(full_ana_dir)
      #vcf = glob.glob('*/*.TSVC_variants.final.vcf')
      #print(vcf)
      
      for final_vcf in glob.glob('*/*.TSVC_variants.final.vcf'):
        barcode = os.path.basename(final_vcf).split('.')[0]
        print(barcode,final_vcf)
        f.write('<a href="%s" target="_blank">%s    %s</a><br>\n'
              % (os.path.join(net_location,file_path,final_vcf),barcode,final_vcf))
        
      
      for indel_summary in glob.glob('*/*.Sens_PPV_Summary.xls'):
        barcode = os.path.basename(indel_summary).split('.')[0]
        print(barcode,indel_summary)
        f.write('<a href="%s" target="_blank">%s    %s</a><br>\n'
              % (os.path.join(net_location,file_path,indel_summary),barcode,indel_summary))

      for snv_summary in glob.glob('*/*.snv.sens.ppv.summary.xls'):
        barcode = os.path.basename(snv_summary).split('.')[0]
        print(barcode,snv_summary)
        f.write('<a href="%s" target="_blank">%s    %s</a><br>\n'
              % (os.path.join(net_location,file_path,indel_summary),barcode,snv_summary))

      f.write('</body></html>')

    return True


if __name__ == "__main__":
    PluginCLI()
