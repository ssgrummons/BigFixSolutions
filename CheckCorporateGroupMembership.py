#!/usr/bin/python
'''
This task can be run on *nix systems to look at an INI file, identify the email from that file, run a corporate API to determine if that user belongs to a specific group, and then write the result to another file.
The results of this can then be parsed by BigFix to target fixlets based on LDAP group memership.
'''

import urllib2
import ConfigParser
import xml.etree.cElementTree as etree
import os

registryfile = "/var/opt/FOLDER/registry.ini"
groupdatfile = "/var/opt/FOLDER/groups.dat"

# Read the ini file to identify the email address.
def ReadISAMdata(file):
   Config = ConfigParser.ConfigParser()
   Config.read(file)
   Config.sections()
   output = Config.get('user', 'intranetid')
   print "Data from INI FILE: " + output
   return output 
   

#  Write LDAP group membership to a file. 
def WriteGroups(file,str,int):
   Config = ConfigParser.ConfigParser()
   Config.read(file)
   if not Config.has_section('LDAPGroupMembership'):
      print "Creating Section LDAPGroupMembership in " + file
      Config.add_section('LDAPGroupMembership')
   if (int == 1) or (Config.has_option('LDAPGroupMembership', group)):
      print "Adding membership key to " + file
      Config.set('LDAPGroupMembership',group, int)
   with open(file, 'wb') as cfgfile:
      Config.write(cfgfile)
   cfgfile.close()


# Create an array of different groups to check.
intranetid = ReadISAMdata(registryfile)
geoList = ["NA","LA"]
numList = ["01","02","03","04","05","06"]
groupList = []
for geo in geoList:
   for num in numList:
      groupname = "MYGROUP-" + geo + "-" + num
      groupList.append(groupname)


# Run the API.  The API produces an XML output that needs to be parsed.
for group in groupList:
   url = "https://ldapdirectory.corporate.com/tools/groups/groupsxml.wss?task=inAGroup&email=" + intranetid + "&group=" + group
   print url
   tree = etree.ElementTree(file=urllib2.urlopen(url))
   root = tree.getroot() 
   status = root[4].text
   if status == "Success":
      print "User is in Group"
      WriteGroups(groupdatfile,group,1)
   else:
      print "User is not in Group"
      if not os.path.isfile(groupdatfile):
         print "File " + groupdatfile + " doesn't exist, no need to create"
      else:
         WriteGroups(groupdatfile,group,0)
   print ""


exit()