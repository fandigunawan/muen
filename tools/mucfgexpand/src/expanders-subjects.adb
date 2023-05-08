--
--  Copyright (C) 2014-2016  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2014-2016  Adrian-Ken Rueegsegger <ken@codelabs.ch>
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

with Interfaces;

with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Containers.Ordered_Sets;

with DOM.Core.Nodes;
with DOM.Core.Elements;
with DOM.Core.Documents;
with DOM.Core.Append_Node;

with McKae.XML.XPath.XIA;

with Mulog;
with Muxml.Utils;
with Mutools.PCI;
with Mutools.Utils;
with Mutools.Types;
with Mutools.XML_Utils;
with Mutools.Constants;
with Mucfgvcpu;
with Mucfgcheck.Validation_Errors;

with Expanders.Config;
with Expanders.Types;
with Expanders.Utils;
with Expanders.XML_Utils;
with Expanders.Subjects.Config;
with Expanders.Subjects.Profiles;

package body Expanders.Subjects
is

   use Ada.Strings.Unbounded;

   package MC renames Mutools.Constants;

   --  Mapping of subject profiles to legacy IRQ vector remapping offset.
   --  Note: Linux uses IRQ0 (vector 48) for the timer.
   Subj_IRQ_Remap_Offset : constant array
     (Types.Subject_Profile_Type) of Natural
     := (Types.Native           => MC.Host_IRQ_Remap_Offset,
         Types.VM | Types.Linux => 48);

   -------------------------------------------------------------------------

   procedure Add_Channel_Events (Data : in out Muxml.XML_Data_Type)
   is
      Writers  : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject/channels/writer");
      Readers  : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject/channels/reader");
      Channels : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/channels/channel[@hasEvent]");
   begin
      Mulog.Log (Msg => "Adding events for" & DOM.Core.Nodes.Length
                 (List => Channels)'Img & " channel(s)");

      for I in 0 .. DOM.Core.Nodes.Length (List => Channels) - 1 loop
         declare
            use type DOM.Core.Node;

            Channel_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Channels,
                 Index => I);
            Channel_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Channel_Node,
                 Name => "name");
            Channel_Mode : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Channel_Node,
                 Name => "hasEvent");
            Writer_Node : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Nodes     => Writers,
                 Ref_Attr  => "physical",
                 Ref_Value => Channel_Name);
            Reader_Node : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Nodes     => Readers,
                 Ref_Attr  => "physical",
                 Ref_Value => Channel_Name);
            Writer_Subj_Source_Group, Reader_Subj_Target_Node : DOM.Core.Node;
         begin
            XML_Utils.Create_Physical_Event_Node
              (Policy => Data,
               Name   => Channel_Name,
               Mode   => Channel_Mode);

            if Writer_Node = null then
               Mucfgcheck.Validation_Errors.Insert
                 (Msg   => "No writer for channel '"
                  & Channel_Name & "'",
                  Fatal => True);
            end if;
            Writer_Subj_Source_Group
              := XML_Utils.Add_Optional_Events_Source_Group
                (Policy  => Data,
                 Subject => Muxml.Utils.Ancestor_Node
                   (Node  => Writer_Node,
                    Level => 2),
                 Group   => Mutools.Types.Vmcall);
            if Reader_Node = null then
               Mucfgcheck.Validation_Errors.Insert
                 (Msg   => "No reader for channel '"
                  & Channel_Name & "'",
                  Fatal => True);
            end if;
            Reader_Subj_Target_Node
              := XML_Utils.Add_Optional_Events_Target
                (Policy  => Data,
                 Subject => Muxml.Utils.Ancestor_Node
                   (Node  => Reader_Node,
                    Level => 2));

            declare
               ID : constant String
                 := DOM.Core.Elements.Get_Attribute
                   (Elem => Writer_Node,
                    Name => "event");
               Vector : constant String
                 := DOM.Core.Elements.Get_Attribute
                   (Elem => Reader_Node,
                    Name => "vector");
               Writer_Phys_Name : constant String
                 := DOM.Core.Elements.Get_Attribute
                   (Elem => Writer_Node,
                    Name => "physical");
               Writer_Log_Name : constant String
                 := DOM.Core.Elements.Get_Attribute
                   (Elem => Writer_Node,
                    Name => "logical");
               Reader_Phys_Name : constant String
                 := DOM.Core.Elements.Get_Attribute
                   (Elem => Reader_Node,
                    Name => "physical");
               Reader_Log_Name : constant String
                 := DOM.Core.Elements.Get_Attribute
                   (Elem => Reader_Node,
                    Name => "logical");
            begin
               Muxml.Utils.Append_Child
                 (Node      => Writer_Subj_Source_Group,
                  New_Child => XML_Utils.Create_Source_Event_Node
                    (Policy        => Data,
                     ID            => ID,
                     Logical_Name  => Writer_Log_Name,
                     Physical_Name => Writer_Phys_Name));
               Muxml.Utils.Append_Child
                 (Node      => Reader_Subj_Target_Node,
                  New_Child => XML_Utils.Create_Target_Event_Node
                    (Policy        => Data,
                     Logical_Name  => Reader_Log_Name,
                     Physical_Name => Reader_Phys_Name,
                     Vector        => Vector));
            end;
         end;
      end loop;
   end Add_Channel_Events;

   -------------------------------------------------------------------------

   procedure Add_Channel_Mappings (Data : in out Muxml.XML_Data_Type)
   is
      Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject/channels/*");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Nodes) - 1 loop
         declare
            Channel_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Nodes,
                 Index => I);
            Channel_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Channel_Node,
                 Name => "physical");
            Logical_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Channel_Node,
                 Name => "logical");
            Channel_Addr : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Channel_Node,
                 Name => "virtualAddress");
            Channel_Writer : constant Boolean
              := DOM.Core.Nodes.Node_Name (N => Channel_Node) = "writer";
            Subj_Node : constant DOM.Core.Node
              := Muxml.Utils.Ancestor_Node
                (Node  => Channel_Node,
                 Level => 2);
            Subj_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Subj_Node,
                 Name => "name");
            Mem_Node : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Doc   => Subj_Node,
                 XPath => "memory");
         begin
            Mulog.Log (Msg => "Mapping channel '" & Channel_Name & "' "
                       & (if Channel_Writer then "writable" else "readable")
                       & " to virtual address " & Channel_Addr
                       & " of subject '" & Subj_Name & "'");
            Muxml.Utils.Append_Child
              (Node      => Mem_Node,
               New_Child => Mutools.XML_Utils.Create_Virtual_Memory_Node
                 (Policy        => Data,
                  Logical_Name  => Logical_Name,
                  Physical_Name => Channel_Name,
                  Address       => Channel_Addr,
                  Writable      => Channel_Writer,
                  Executable    => False));
         end;
      end loop;
   end Add_Channel_Mappings;

   -------------------------------------------------------------------------

   procedure Add_CPU_IDs (Data : in out Muxml.XML_Data_Type)
   is
      Group_Subjects : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/scheduling/partitions/partition/group/subject");
      Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Nodes) - 1 loop
         declare
            use type DOM.Core.Node;

            Subj_Node  : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Nodes,
                 Index => I);
            Subj_Name  : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Subj_Node,
                 Name => "name");
            Sched_Part : constant DOM.Core.Node
              := Muxml.Utils.Ancestor_Node
                (Node  => Muxml.Utils.Get_Element
                   (Nodes     => Group_Subjects,
                    Ref_Attr  => "name",
                    Ref_Value => Subj_Name),
                 Level => 2);
            CPU_ID_Str : constant String
              := DOM.Core.Elements.Get_Attribute
                                (Elem => Sched_Part,
                                 Name => "cpu");
         begin
            Mulog.Log (Msg => "Setting cpu of subject '" & Subj_Name
                       & "' to " & CPU_ID_Str);
            DOM.Core.Elements.Set_Attribute (Elem  => Subj_Node,
                                             Name  => "cpu",
                                             Value => CPU_ID_Str);
         end;
      end loop;
   end Add_CPU_IDs;

   -------------------------------------------------------------------------

   procedure Add_Default_Events (Data : in out Muxml.XML_Data_Type)
   is
      Nodes  : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject/events/source/group/default");

      --  Returns True if an event with specified reference ID exists in the
      --  given node list.
      function ID_Exists
        (Nodes  : DOM.Core.Node_List;
         Ref_ID : Natural)
         return Boolean;

      ----------------------------------------------------------------------

      function ID_Exists
        (Nodes  : DOM.Core.Node_List;
         Ref_ID : Natural)
         return Boolean
      is
      begin
         for I in 0 .. DOM.Core.Nodes.Length (List => Nodes) - 1 loop
            declare
               Node : constant DOM.Core.Node
                 := DOM.Core.Nodes.Item
                   (List  => Nodes,
                    Index => I);
               ID_Str : constant String := DOM.Core.Elements.Get_Attribute
                 (Elem => Node,
                  Name => "id");
            begin
               if Natural'Value (ID_Str) = Ref_ID then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end ID_Exists;
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Nodes) - 1 loop
         declare
            Def_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Nodes,
                 Index => I);
            Def_Action : constant DOM.Core.Node
              := Muxml.Utils.Get_Element (Doc   => Def_Node,
                                          XPath => "*");
            Physical_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Def_Node,
                 Name => "physical");
            Group_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Parent_Node (N => Def_Node);
            Group_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Group_Node,
                 Name => "name");
            Group : constant Mutools.Types.Event_Group_Type
              := Mutools.Types.Event_Group_Type'Value (Group_Name);
            Group_Events : constant DOM.Core.Node_List
              := McKae.XML.XPath.XIA.XPath_Query
                (N     => Group_Node,
                 XPath => "event");
            Subj_Node : constant DOM.Core.Node
              := Muxml.Utils.Ancestor_Node
                (Node  => Def_Node,
                 Level => 4);
            Subj_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Subj_Node,
                 Name => "name");
            Group_Max_Event : constant Natural := Mutools.Types.Get_Max_ID
              (Group => Group);
         begin
            Mulog.Log (Msg => "Adding default events to event group '"
                       & Group_Name & "' of subject '" & Subj_Name & "'");

            for ID in Natural range 0 .. Group_Max_Event loop
               declare
                  use type DOM.Core.Node;

                  ID_Str : constant String := Ada.Strings.Fixed.Trim
                    (Source => ID'Img,
                     Side   => Ada.Strings.Left);
                  Ev_Node : DOM.Core.Node;
               begin
                  if Mutools.Types.Is_Valid_Event_ID
                    (Group => Group,
                     ID    => ID)
                    and then
                      not ID_Exists (Nodes  => Group_Events,
                                     Ref_ID => ID)
                  then
                     Ev_Node := XML_Utils.Create_Source_Event_Node
                       (Policy        => Data,
                        ID            => ID_Str,
                        Logical_Name  => "default_event_" & ID_Str,
                        Physical_Name => Physical_Name);
                     if Def_Action /= null then
                        Muxml.Utils.Append_Child
                          (Node      => Ev_Node,
                           New_Child => DOM.Core.Nodes.Clone_Node
                             (N    => Def_Action,
                              Deep => True));
                     end if;

                     Muxml.Utils.Append_Child
                       (Node      => Group_Node,
                        New_Child => Ev_Node);
                  end if;
               end;
            end loop;

            Muxml.Utils.Remove_Child (Node       => Group_Node,
                                      Child_Name => "default");
         end;
      end loop;
   end Add_Default_Events;

   -------------------------------------------------------------------------

   procedure Add_Device_BDFs (Data : in out Muxml.XML_Data_Type)
   is
      PCI_Devices : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/hardware/devices/device[pci]");
      Subjects    : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject[devices/device]");

      --  Return all subject devices that are part of a physical PCI
      --  multi-function device with the given physical device. The specified
      --  physical device is always included in the returned list.
      function Get_All_Device_Functions_Refs
        (Subject_Devices : DOM.Core.Node_List;
         Physical_Device : DOM.Core.Node)
         return DOM.Core.Node_List;

      --  The procedure checks if the given subject is part of a subject
      --  sibling group. If it is, it updates the given node lists with the
      --  devices of all subjects in the group. This is required to assign a
      --  device BDF which is unique in the whole group.
      procedure Create_Subj_Siblings_View
        (Subject          :        DOM.Core.Node;
         Assigned_BDFs    : in out DOM.Core.Node_List;
         All_Subject_Devs : in out DOM.Core.Node_List;
         Subject_Devs     : in out DOM.Core.Node_List);

      ----------------------------------------------------------------------

      procedure Create_Subj_Siblings_View
        (Subject          :        DOM.Core.Node;
         Assigned_BDFs    : in out DOM.Core.Node_List;
         All_Subject_Devs : in out DOM.Core.Node_List;
         Subject_Devs     : in out DOM.Core.Node_List)
      is
         use type DOM.Core.Node;

         Subj_Name : constant String
           := DOM.Core.Elements.Get_Attribute
             (Elem => Subject,
              Name => "name");
         Is_Sibling : constant Boolean
           := Muxml.Utils.Get_Element
             (Doc   => Subject,
              XPath => "sibling") /= null;
         Sib_XPath : constant String
           := "/system/subjects/subject/sibling";
         Is_Origin : constant Boolean
           := DOM.Core.Nodes.Length
             (List => McKae.XML.XPath.XIA.XPath_Query
                (N     => Data.Doc,
                 XPath => Sib_XPath & "[@ref='" & Subj_Name & "']")) > 0;
      begin
         if Is_Origin or else Is_Sibling then
            declare
               Query_Name : constant String
                 := (if Is_Origin then Subj_Name
                     else DOM.Core.Elements.Get_Attribute
                       (Elem => Muxml.Utils.Get_Element
                            (Doc   => Subject,
                             XPath => "sibling"),
                        Name => "ref"));
               Orig_Devs_XPath : constant String
                 := "/system/subjects/subject[@name='" & Query_Name
                 & "']/devices/device";
               Sib_Devs_XPath : constant String
                 := Sib_XPath & "[@ref='" & Query_Name
                 & "']/../devices/device";
            begin
               Assigned_BDFs := McKae.XML.XPath.XIA.XPath_Query
                 (N     => Data.Doc,
                  XPath => Sib_Devs_XPath & "/pci");
               Muxml.Utils.Append
                 (Left  => Assigned_BDFs,
                  Right => McKae.XML.XPath.XIA.XPath_Query
                    (N     => Data.Doc,
                     XPath => Orig_Devs_XPath & "/pci"));
               Subject_Devs := McKae.XML.XPath.XIA.XPath_Query
                 (N     => Data.Doc,
                  XPath => Sib_Devs_XPath & "[not(pci)]");
               Muxml.Utils.Append
                 (Left  => Subject_Devs,
                  Right => McKae.XML.XPath.XIA.XPath_Query
                    (N     => Data.Doc,
                     XPath => Orig_Devs_XPath & "[not(pci)]"));
               All_Subject_Devs := McKae.XML.XPath.XIA.XPath_Query
                 (N     => Data.Doc,
                  XPath => Sib_Devs_XPath);
               Muxml.Utils.Append
                 (Left  => All_Subject_Devs,
                  Right => McKae.XML.XPath.XIA.XPath_Query
                    (N     => Data.Doc,
                     XPath => Orig_Devs_XPath));
            end;
         end if;
      end Create_Subj_Siblings_View;

      ----------------------------------------------------------------------

      function Get_All_Device_Functions_Refs
        (Subject_Devices : DOM.Core.Node_List;
         Physical_Device : DOM.Core.Node)
         return DOM.Core.Node_List
      is
         Bus_Nr        : constant String
           := Muxml.Utils.Get_Attribute
             (Doc   => Physical_Device,
              XPath => "pci",
              Name  => "bus");
         Dev_Nr        : constant String
           := Muxml.Utils.Get_Attribute
             (Doc   => Physical_Device,
              XPath => "pci",
              Name  => "device");
         Phys_Siblings : constant DOM.Core.Node_List
           := McKae.XML.XPath.XIA.XPath_Query
             (N     => Data.Doc,
              XPath => "/system/hardware/devices/device/pci[@bus='" & Bus_Nr
              & "' and @device='" & Dev_Nr & "']/..");

         Sibling_Devs : DOM.Core.Node_List;
      begin
         for I in 0 .. DOM.Core.Nodes.Length (List => Phys_Siblings) - 1 loop
            declare
               use type DOM.Core.Node;

               Phys_Dev  : constant DOM.Core.Node
                 := DOM.Core.Nodes.Item (List  => Phys_Siblings,
                                         Index => I);
               Phys_Name : constant String
                 := DOM.Core.Elements.Get_Attribute
                   (Elem => Phys_Dev,
                    Name => "name");
               Log_Dev : constant DOM.Core.Node := Muxml.Utils.Get_Element
                 (Nodes     => Subject_Devices,
                  Ref_Attr  => "physical",
                  Ref_Value => Phys_Name);
            begin
               if Log_Dev /= null then
                  DOM.Core.Append_Node
                    (List => Sibling_Devs,
                     N    => Log_Dev);
               end if;
            end;
         end loop;

         return Sibling_Devs;
      end Get_All_Device_Functions_Refs;
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Subjects) - 1 loop
         declare
            Subject       : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Subjects,
                 Index => I);
            All_Subj_Devs : DOM.Core.Node_List
              := McKae.XML.XPath.XIA.XPath_Query
                (N     => Subject,
                 XPath => "devices/device");
            Subject_Devs  : DOM.Core.Node_List
              := McKae.XML.XPath.XIA.XPath_Query
                (N     => Subject,
                 XPath => "devices/device[not (pci)]");
            Assigned_BDFs : DOM.Core.Node_List
              := McKae.XML.XPath.XIA.XPath_Query
                (N     => Subject,
                 XPath => "devices/device/pci");
            Dev_Nr_Allocator : Utils.Number_Allocator_Type (Range_Start => 1,
                                                            Range_End   => 31);
         begin
            Create_Subj_Siblings_View (Subject          => Subject,
                                       Assigned_BDFs    => Assigned_BDFs,
                                       All_Subject_Devs => All_Subj_Devs,
                                       Subject_Devs     => Subject_Devs);
            Utils.Reserve_Numbers (Allocator => Dev_Nr_Allocator,
                                   Nodes     => Assigned_BDFs,
                                   Attribute => "device");

            for J in 0 .. DOM.Core.Nodes.Length (List => Subject_Devs) - 1
            loop
               declare
                  use type DOM.Core.Node;

                  Subj_Dev  : constant DOM.Core.Node
                    := DOM.Core.Nodes.Item
                      (List  => Subject_Devs,
                       Index => J);
                  Phys_Name : constant String
                    := DOM.Core.Elements.Get_Attribute
                      (Elem => Subj_Dev,
                       Name => "physical");
                  Phys_Dev  : constant DOM.Core.Node
                    := Muxml.Utils.Get_Element
                      (Nodes     => PCI_Devices,
                       Ref_Attr  => "name",
                       Ref_Value => Phys_Name);
               begin

                  --  Phys_Dev may be null if referenced physical device is not
                  --  a PCI device.

                  if Phys_Dev /= null then
                     declare
                        Siblings         : constant DOM.Core.Node_List
                          := Get_All_Device_Functions_Refs
                            (Subject_Devices => All_Subj_Devs,
                             Physical_Device => Phys_Dev);
                        Device_Nr        : Natural := 0;
                        Fun_Nr_Allocator : Utils.Number_Allocator_Type
                          (Range_Start => 0,
                           Range_End   => 7);

                        Devs_To_Allocate : DOM.Core.Node_List;
                     begin
                        for K in 0 .. DOM.Core.Nodes.Length
                          (List => Siblings) - 1
                        loop
                           declare
                              Cur_Sibling : constant DOM.Core.Node
                                := DOM.Core.Nodes.Item (List  => Siblings,
                                                        Index => K);
                              Dev_Nr      : constant String
                                := Muxml.Utils.Get_Attribute
                                  (Doc   => Cur_Sibling,
                                   XPath => "pci",
                                   Name  => "device");
                              Fun_Nr      : constant String
                                := Muxml.Utils.Get_Attribute
                                  (Doc   => Cur_Sibling,
                                   XPath => "pci",
                                   Name  => "function");
                           begin
                              if Dev_Nr'Length > 0 then

                                 --  Sibling has logical BDF already set in the
                                 --  policy. Remember assigned device number
                                 --  for later allocation step and reserve
                                 --  assigned function number.

                                 Device_Nr := Natural'Value (Dev_Nr);

                                 Utils.Reserve_Number
                                   (Allocator => Fun_Nr_Allocator,
                                    Number    => Natural'Value (Fun_Nr));
                              else

                                 --  Sibling has no logical BDF, store it in
                                 --  list of devices to allocate BDFs.

                                 DOM.Core.Append_Node
                                   (List => Devs_To_Allocate,
                                    N    => Cur_Sibling);
                              end if;
                           end;
                        end loop;

                        if Device_Nr = 0 then

                           --  Get next free device number if no sibling device
                           --  had a logical BDF assigned in the policy.

                           Utils.Allocate (Allocator => Dev_Nr_Allocator,
                                           Number    => Device_Nr);
                        end if;

                        for L in 0 .. DOM.Core.Nodes.Length
                          (List => Devs_To_Allocate) - 1
                        loop
                           declare
                              Alloc_Dev  : constant DOM.Core.Node
                                := DOM.Core.Nodes.Item
                                  (List  => Devs_To_Allocate,
                                   Index => L);
                              Log_Name   : constant String
                                := DOM.Core.Elements.Get_Attribute
                                  (Elem => Alloc_Dev,
                                   Name => "logical");
                              PCI_Node   : DOM.Core.Node;
                              Fun_Number : Natural;
                           begin
                              Utils.Allocate (Allocator => Fun_Nr_Allocator,
                                              Number    => Fun_Number);
                              Mulog.Log
                                (Msg => "Setting BDF of logical device '"
                                 & Log_Name & "' to 00:"
                                 & Mutools.Utils.To_Hex
                                   (Number     => Interfaces.Unsigned_64
                                        (Device_Nr),
                                    Normalize  => False,
                                    Byte_Short => True) & "."
                                 & Ada.Strings.Fixed.Trim
                                   (Source => Fun_Number'Img,
                                    Side   => Ada.Strings.Left));

                              PCI_Node := Mutools.PCI.Create_PCI_Node
                                (Policy => Data,
                                 Bus    => 0,
                                 Device => Mutools.PCI.Device_Range
                                   (Device_Nr),
                                 Func   => Mutools.PCI.Function_Range
                                   (Fun_Number));

                              PCI_Node := DOM.Core.Nodes.Insert_Before
                                (N         => Alloc_Dev,
                                 New_Child => PCI_Node,
                                 Ref_Child => DOM.Core.Nodes.First_Child
                                   (N => Alloc_Dev));
                           end;
                        end loop;
                     end;
                  end if;
               end;
            end loop;
         end;
      end loop;
   end Add_Device_BDFs;

   -------------------------------------------------------------------------

   procedure Add_Device_Memory_Mappings (Data : in out Muxml.XML_Data_Type)
   is
      Devices_Node : constant DOM.Core.Node
        := Muxml.Utils.Get_Element
          (Doc   => Data.Doc,
           XPath => "/system/hardware/devices");
      Unmapped_Memory : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject/devices/device/memory"
           & "[not (@virtualAddress)]");
      Count : constant Natural := DOM.Core.Nodes.Length
        (List => Unmapped_Memory);
   begin
      if Count = 0 then
         return;
      end if;

      Mulog.Log (Msg => "Adding" & Count'Img & " mapping(s) for device "
                 & "memory");

      for I in 0 .. Count - 1 loop
         declare
            Memory_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Unmapped_Memory,
                 Index => I);
            Memory_Ref : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Memory_Node,
                 Name => "physical");
            Dev_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Parent_Node (N => Memory_Node);
            Dev_Ref : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Dev_Node,
                 Name => "physical");
            Physmem_Addr : constant Interfaces.Unsigned_64
              := Interfaces.Unsigned_64'Value
                (Muxml.Utils.Get_Attribute
                   (Doc   => Data.Doc,
                    XPath => "/system/hardware/devices/device[@name='"
                    & Dev_Ref & "']/memory[@name='" & Memory_Ref & "']",
                    Name  => "physicalAddress"));
            Mapping_Addr : Interfaces.Unsigned_64 := Physmem_Addr;
         begin
            if Mutools.XML_Utils.Is_Physical_Mmconf_Region
              (Devices_Node => Devices_Node,
               Addr         => Physmem_Addr)
            then
               Mapping_Addr := Mutools.XML_Utils.Calculate_PCI_Cfg_Address
                 (Base_Address => MC.Subject_PCI_Config_Space_Addr,
                  PCI_Node     => Muxml.Utils.Get_Element
                    (Doc   => Dev_Node,
                     XPath => "pci"));
            end if;

            DOM.Core.Elements.Set_Attribute
              (Elem  => Memory_Node,
               Name  => "virtualAddress",
               Value => Mutools.Utils.To_Hex (Number => Mapping_Addr));
         end;
      end loop;
   end Add_Device_Memory_Mappings;

   -------------------------------------------------------------------------

   procedure Add_Device_MSIs (Data : in out Muxml.XML_Data_Type)
   is
      Ref_IRQ_Tags : constant Muxml.Utils.Tags_Type
        := (1 => To_Unbounded_String ("memory"),
            2 => To_Unbounded_String ("ioPort"));

      Subj_Devs : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject/devices/device[irq/msi]");
   begin
      for I in Natural range 0 .. DOM.Core.Nodes.Length (List => Subj_Devs) - 1
      loop
         declare
            Subj_Dev : constant DOM.Core.Node
              := DOM.Core.Nodes.Item (List  => Subj_Devs,
                                      Index => I);
            Log_Name : constant String
              := DOM.Core.Elements.Get_Attribute (Elem => Subj_Dev,
                                                  Name => "logical");
            Subj_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Muxml.Utils.Ancestor_Node
                   (Node  => Subj_Dev,
                    Level => 2),
                 Name => "name");
            Vec_Str : constant String
              := Muxml.Utils.Get_Attribute
                (Doc   => Subj_Dev,
                 XPath => "irq[msi]",
                 Name  => "vector");
            Cur_Vector : Natural := (if Vec_Str'Length = 0 then 0 else
                                        Natural'Value (Vec_Str));
            MSIs : constant DOM.Core.Node_List
              := McKae.XML.XPath.XIA.XPath_Query
                (N     => Subj_Dev,
                 XPath => "irq/msi");
            MSI_Count : constant Natural
              := DOM.Core.Nodes.Length (List => MSIs);
         begin
            Mulog.Log (Msg => "Adding" & MSI_Count'Img
                       & " MSI IRQs to logical device '" & Log_Name
                       & "' of subject '" & Subj_Name & "'");

            for J in Natural range 0 .. MSI_Count - 1 loop
               declare
                  MSI : constant DOM.Core.Node
                    := DOM.Core.Nodes.Item (List  => MSIs,
                                            Index => J);
                  New_Irq : constant DOM.Core.Node
                    := DOM.Core.Documents.Create_Element
                      (Doc      => Data.Doc,
                       Tag_Name => "irq");
               begin
                  DOM.Core.Elements.Set_Attribute
                    (Elem  => New_Irq,
                     Name  => "logical",
                     Value => DOM.Core.Elements.Get_Attribute
                       (Elem => MSI,
                        Name => "logical"));
                  DOM.Core.Elements.Set_Attribute
                    (Elem  => New_Irq,
                     Name  => "physical",
                     Value => DOM.Core.Elements.Get_Attribute
                       (Elem => MSI,
                        Name => "physical"));
                  if Cur_Vector > 0 then
                     DOM.Core.Elements.Set_Attribute
                       (Elem  => New_Irq,
                        Name  => "vector",
                        Value => Ada.Strings.Fixed.Trim
                          (Source => Cur_Vector'Img,
                           Side   => Ada.Strings.Left));
                     Cur_Vector := Cur_Vector + 1;
                  end if;

                  Muxml.Utils.Insert_Before
                    (Parent    => Subj_Dev,
                     New_Child => New_Irq,
                     Ref_Names => Ref_IRQ_Tags);
               end;
            end loop;
         end;
      end loop;
   end Add_Device_MSIs;

   -------------------------------------------------------------------------

   procedure Add_Device_Resources (Data : in out Muxml.XML_Data_Type)
   is
      Devices : constant DOM.Core.Node
        := Muxml.Utils.Get_Element
          (Doc   => Data.Doc,
           XPath => "/system/hardware/devices");
      Phys_Devs : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/hardware/devices/device[*]");
      Subj_Devs : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject/devices/device[not(*)"
           & " or (count(*)=1 and pci)]");

      --  Add logical mappings for all resources of given physical node to
      --  specified logical parent node.
      procedure Add_Physical_Resources
        (Logical_Parent_Node    : DOM.Core.Node;
         Physical_Parent_Node   : DOM.Core.Node;
         Mmconf_Devices_Node    : DOM.Core.Node;
         Mmconf_Device_PCI_Node : DOM.Core.Node);

      ----------------------------------------------------------------------

      procedure Add_Physical_Resources
        (Logical_Parent_Node    : DOM.Core.Node;
         Physical_Parent_Node   : DOM.Core.Node;
         Mmconf_Devices_Node    : DOM.Core.Node;
         Mmconf_Device_PCI_Node : DOM.Core.Node)
      is
         Phys_Resources : constant DOM.Core.Node_List
           := McKae.XML.XPath.XIA.XPath_Query
             (N     => Physical_Parent_Node,
              XPath => "memory|irq|ioPort|msi");
         Phys_Res_Count : constant Natural
           := DOM.Core.Nodes.Length (List => Phys_Resources);
      begin
         for I in 0 .. Phys_Res_Count - 1 loop
            declare
               Phys_Res : constant DOM.Core.Node
                 := DOM.Core.Nodes.Item (List  => Phys_Resources,
                                         Index => I);
               Logical_Res : DOM.Core.Node;
            begin
               Logical_Res := Mutools.XML_Utils.Add_Resource
                 (Logical_Device         => Logical_Parent_Node,
                  Physical_Resource      => Phys_Res,
                  Mmconf_Devices_Node    => Mmconf_Devices_Node,
                  Mmconf_Device_PCI_Node => Mmconf_Device_PCI_Node,
                  Mmconf_Virt_Base       => MC.Subject_PCI_Config_Space_Addr);

               --  Recursively add physical resources.

               Add_Physical_Resources
                 (Logical_Parent_Node    => Logical_Res,
                  Physical_Parent_Node   => Phys_Res,
                  Mmconf_Devices_Node    => Mmconf_Devices_Node,
                  Mmconf_Device_PCI_Node => Mmconf_Device_PCI_Node);
            end;
         end loop;
      end Add_Physical_Resources;
   begin
      for I in 1 .. DOM.Core.Nodes.Length (List => Subj_Devs) loop
         declare
            use type DOM.Core.Node;

            Subj_Dev : constant DOM.Core.Node
              := DOM.Core.Nodes.Item (List  => Subj_Devs,
                                      Index => I - 1);
            Subj_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Muxml.Utils.Ancestor_Node
                   (Node  => Subj_Dev,
                    Level => 2),
                 Name => "name");
            Log_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Subj_Dev,
                 Name => "logical");
            Phys_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Subj_Dev,
                 Name => "physical");
            Phys_Dev : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Nodes     => Phys_Devs,
                 Ref_Attr  => "name",
                 Ref_Value => Phys_Name);
         begin
            if Phys_Dev /= null then
               Mulog.Log (Msg => "Adding device resources of physical device '"
                          & Phys_Name & "' to logical device '" & Log_Name
                          & "' of subject '" & Subj_Name & "'");
               declare
                  Subj_Dev_PCI : constant DOM.Core.Node
                    := Muxml.Utils.Get_Element
                      (Doc   => Subj_Dev,
                       XPath => "pci");
               begin
                  Add_Physical_Resources
                    (Logical_Parent_Node    => Subj_Dev,
                     Physical_Parent_Node   => Phys_Dev,
                     Mmconf_Devices_Node    => Devices,
                     Mmconf_Device_PCI_Node => Subj_Dev_PCI);
               end;
            end if;
         end;
      end loop;
   end Add_Device_Resources;

   -------------------------------------------------------------------------

   procedure Add_Device_Vectors (Data : in out Muxml.XML_Data_Type)
   is
      PCI_MSI_Devs : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/hardware/devices/device[pci/@msi='true']");
      Subjects     : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject[devices/device]");

      --  Allocate vectors for IRQs of the specified logical device using the
      --  given allocator. If 'Consecutive' is set to True, the IRQs are
      --  allocated consecutively.
      procedure Allocate_Vectors
        (Logical_Device :        DOM.Core.Node;
         Allocator      : in out Utils.Number_Allocator_Type;
         Consecutive    :        Boolean := False);

      --  The procedure checks if the given subject is part of a subject
      --  sibling group. If it is, it updates the given node lists with the
      --  device/event vectors of all subjects in the group. This is required
      --  to assign an IRQ vector which is unique in the whole group.
      procedure Create_Subj_Siblings_View
        (Subject        :        DOM.Core.Node;
         Device_Vectors : in out DOM.Core.Node_List;
         Event_Vectors  : in out DOM.Core.Node_List);

      ----------------------------------------------------------------------

      procedure Allocate_Vectors
        (Logical_Device :        DOM.Core.Node;
         Allocator      : in out Utils.Number_Allocator_Type;
         Consecutive    :        Boolean := False)
      is
         IRQs : constant DOM.Core.Node_List
           := McKae.XML.XPath.XIA.XPath_Query
             (N     => Logical_Device,
              XPath => "irq[not(@vector)]");
         IRQ_Count : constant Natural := DOM.Core.Nodes.Length (List => IRQs);
      begin
         if Consecutive then
            declare
               Cur_Idx, Cur_End : Natural;
            begin
               Utils.Allocate_Range
                 (Allocator   => Allocator,
                  Range_Size  => IRQ_Count,
                  Range_Start => Cur_Idx,
                  Range_End   => Cur_End);
               for I in 0 .. IRQ_Count - 1 loop
                  declare
                     Cur_Irq : constant DOM.Core.Node
                       := DOM.Core.Nodes.Item
                         (List  => IRQs,
                          Index => I);
                  begin
                     DOM.Core.Elements.Set_Attribute
                       (Elem  => Cur_Irq,
                        Name  => "vector",
                        Value => Ada.Strings.Fixed.Trim
                          (Source => Cur_Idx'Img,
                           Side   => Ada.Strings.Left));
                     Cur_Idx := Cur_Idx + 1;
                  end;
               end loop;

               pragma Assert
                 (Check   => Cur_Idx = Cur_End + 1,
                  Message => "Vector range and IRQ count mismatch");
            end;
         else
            for I in 0 .. IRQ_Count - 1 loop
               declare
                  Cur_Irq    : constant DOM.Core.Node
                    := DOM.Core.Nodes.Item
                      (List  => IRQs,
                       Index => I);
                  Cur_Vector : Natural;
               begin
                  Utils.Allocate (Allocator => Allocator,
                                  Number    => Cur_Vector);
                  DOM.Core.Elements.Set_Attribute
                    (Elem  => Cur_Irq,
                     Name  => "vector",
                     Value => Ada.Strings.Fixed.Trim
                       (Source => Cur_Vector'Img,
                        Side   => Ada.Strings.Left));
               end;
            end loop;
         end if;
      end Allocate_Vectors;

      ----------------------------------------------------------------------

      procedure Create_Subj_Siblings_View
        (Subject        :        DOM.Core.Node;
         Device_Vectors : in out DOM.Core.Node_List;
         Event_Vectors  : in out DOM.Core.Node_List)
      is
         use type DOM.Core.Node;

         Subj_Name : constant String
           := DOM.Core.Elements.Get_Attribute
             (Elem => Subject,
              Name => "name");
         Is_Sibling : constant Boolean
           := Muxml.Utils.Get_Element
             (Doc   => Subject,
              XPath => "sibling") /= null;
         Sib_XPath : constant String
           := "/system/subjects/subject/sibling";
         Is_Origin : constant Boolean
           := DOM.Core.Nodes.Length
             (List => McKae.XML.XPath.XIA.XPath_Query
                (N     => Data.Doc,
                 XPath => Sib_XPath & "[@ref='" & Subj_Name & "']")) > 0;
      begin
         if Is_Origin or else Is_Sibling then
            declare
               Query_Name : constant String
                 := (if Is_Origin then Subj_Name
                     else DOM.Core.Elements.Get_Attribute
                       (Elem => Muxml.Utils.Get_Element
                            (Doc   => Subject,
                             XPath => "sibling"),
                        Name => "ref"));
               Orig_Subj_XPath : constant String
                 := "/system/subjects/subject[@name='" & Query_Name & "']";
               Orig_Dev_Vecs_XPath : constant String
                 := Orig_Subj_XPath & "/devices/device/irq[@vector]";
               Orig_Evt_Vecs_XPath : constant String
                 := Orig_Subj_XPath & "/events/target/event/inject_interrupt";

               Sib_Subj_XPath : constant String
                 := Sib_XPath & "[@ref='" & Query_Name & "']/..";
               Sib_Dev_Vecs_XPath : constant String
                 := Sib_Subj_XPath & "/devices/device/irq[@vector]";
               Sib_Evt_Vecs_XPath : constant String
                 := Sib_Subj_XPath & "/events/target/event/inject_interrupt";
            begin
               Device_Vectors := McKae.XML.XPath.XIA.XPath_Query
                 (N     => Data.Doc,
                  XPath => Sib_Dev_Vecs_XPath);
               Muxml.Utils.Append
                 (Left  => Device_Vectors,
                  Right => McKae.XML.XPath.XIA.XPath_Query
                    (N     => Data.Doc,
                     XPath => Orig_Dev_Vecs_XPath));

               Event_Vectors := McKae.XML.XPath.XIA.XPath_Query
                 (N     => Data.Doc,
                  XPath => Sib_Evt_Vecs_XPath);
               Muxml.Utils.Append
                 (Left  => Event_Vectors,
                  Right => McKae.XML.XPath.XIA.XPath_Query
                    (N     => Data.Doc,
                     XPath => Orig_Evt_Vecs_XPath));
            end;
         end if;
      end Create_Subj_Siblings_View;
   begin
      for I in 1 .. DOM.Core.Nodes.Length (List => Subjects) loop
         declare
            use type Types.Subject_Profile_Type;

            Subject        : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Subjects,
                 Index => I - 1);
            Subject_Name   : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Subject,
                 Name => "name");
            Subj_Profile   : constant Types.Subject_Profile_Type
              := Types.Subject_Profile_Type'Value
                (DOM.Core.Elements.Get_Attribute
                   (Elem => Subject,
                    Name => "profile"));
            Alloc_Devs     : constant DOM.Core.Node_List
              := McKae.XML.XPath.XIA.XPath_Query
                (N     => Subject,
                 XPath => "devices/device/irq[not(@vector)]/..");
            Alloc_Count    : constant Natural
              := DOM.Core.Nodes.Length (List => Alloc_Devs);
            Device_Vectors : DOM.Core.Node_List
              := McKae.XML.XPath.XIA.XPath_Query
                (N     => Subject,
                 XPath => "devices/device/irq[@vector]");
            Event_Vectors  : DOM.Core.Node_List
              := McKae.XML.XPath.XIA.XPath_Query
                (N     => Subject,
                 XPath => "events/target/event/inject_interrupt");
            IRQ_Alloc      : Utils.Number_Allocator_Type
              (Range_Start => Subj_IRQ_Remap_Offset (Subj_Profile),
               Range_End   => 255);
         begin
            if Alloc_Count > 0 then
               Create_Subj_Siblings_View (Subject        => Subject,
                                          Device_Vectors => Device_Vectors,
                                          Event_Vectors  => Event_Vectors);

               Mulog.Log (Msg => "Allocating logical IRQ vector(s) for subject"
                          & " '" & Subject_Name & "'");

               Utils.Reserve_Numbers (Allocator => IRQ_Alloc,
                                      Nodes     => Device_Vectors,
                                      Attribute => "vector");
               Utils.Reserve_Numbers (Allocator => IRQ_Alloc,
                                      Nodes     => Event_Vectors,
                                      Attribute => "vector");

               if Subj_Profile = Types.Linux then

                  --  Reserve IRQ0 .. IRQ15 to avoid clashes with Linux legacy
                  --  device drivers.

                  for J in IRQ_Alloc.Range_Start .. IRQ_Alloc.Range_Start + 16
                  loop
                     Utils.Reserve_Number (Allocator => IRQ_Alloc,
                                           Number    => J);
                  end loop;
               end if;

               for J in 1 .. DOM.Core.Nodes.Length (List => Alloc_Devs) loop
                  declare
                     use type DOM.Core.Node;

                     Cur_Dev : constant DOM.Core.Node
                       := DOM.Core.Nodes.Item
                         (List  => Alloc_Devs,
                          Index => J - 1);
                     Phys_Name : constant String
                       := DOM.Core.Elements.Get_Attribute
                         (Elem => Cur_Dev,
                          Name => "physical");
                     Phys_MSI_Dev : constant DOM.Core.Node
                       := Muxml.Utils.Get_Element
                         (Nodes     => PCI_MSI_Devs,
                          Ref_Attr  => "name",
                          Ref_Value => Phys_Name);
                  begin
                     Allocate_Vectors (Logical_Device => Cur_Dev,
                                       Allocator      => IRQ_Alloc,
                                       Consecutive    => Phys_MSI_Dev /= null);
                  end;
               end loop;
            end if;
         end;
      end loop;
   end Add_Device_Vectors;

   -------------------------------------------------------------------------

   procedure Add_Global_IDs (Data : in out Muxml.XML_Data_Type)
   is
      Nodes  : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject[not (@globalId)]");
      Cur_ID : Natural
        := (if Mutools.XML_Utils.Is_Tau0_Scheduled (Data => Data)
            then 1 else 0);
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Nodes) - 1 loop
         declare
            Subj_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Nodes,
                 Index => I);
            Subj_Name : constant String := DOM.Core.Elements.Get_Attribute
              (Elem => Subj_Node,
               Name => "name");
            ID_Str    : constant String := Ada.Strings.Fixed.Trim
              (Source => Cur_ID'Img,
               Side   => Ada.Strings.Left);
         begin
            Mulog.Log (Msg => "Setting global ID of subject '" & Subj_Name
                       & "' to " & ID_Str);
            DOM.Core.Elements.Set_Attribute
              (Elem  => Subj_Node,
               Name  => "globalId",
               Value => ID_Str);
            Cur_ID := Cur_ID + 1;
         end;
      end loop;
   end Add_Global_IDs;

   -------------------------------------------------------------------------

   procedure Add_Local_IDs (Data : in out Muxml.XML_Data_Type)
   is
      Subjects  : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject[not (@localId)]");
      CPU_Count : constant Positive
        := Mutools.XML_Utils.Get_Active_CPU_Count (Data => Data);

      Cur_CPU_ID : array (Natural range 0 .. CPU_Count - 1) of Natural
        := (others => 0);
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Subjects) - 1 loop
         declare
            Cur_Subj  : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Subjects,
                 Index => I);
            Subj_Name : constant String := DOM.Core.Elements.Get_Attribute
              (Elem => Cur_Subj,
               Name => "name");
            Cur_CPU   : constant Natural := Natural'Value
              (DOM.Core.Elements.Get_Attribute
                 (Elem => Cur_Subj,
                  Name => "cpu"));
            Cur_ID    : constant String
              := Ada.Strings.Fixed.Trim
                (Source => Cur_CPU_ID (Cur_CPU)'Img,
                 Side   => Ada.Strings.Left);
         begin
            Mulog.Log (Msg => "Setting local ID of subject '" & Subj_Name
                       & "' to " & Cur_ID);
            DOM.Core.Elements.Set_Attribute
              (Elem  => Cur_Subj,
               Name  => "localId",
               Value => Cur_ID);

            Cur_CPU_ID (Cur_CPU) := Cur_CPU_ID (Cur_CPU) + 1;
         end;
      end loop;
   end Add_Local_IDs;

   -------------------------------------------------------------------------

   procedure Add_Missing_Elements (Data : in out Muxml.XML_Data_Type)
   is
      Subjects : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Subjects) - 1 loop
         declare
            use type DOM.Core.Node;

            Subj_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Subjects,
                 Index => I);
            VCPU_Node : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Doc   => Subj_Node,
                 XPath => "vcpu");
         begin
            Muxml.Utils.Add_Child
              (Parent     => Subj_Node,
               Child_Name => "devices",
               Ref_Names  => (1 => To_Unbounded_String ("events")));
            Muxml.Utils.Add_Child
              (Parent     => Subj_Node,
               Child_Name => "memory",
               Ref_Names  => (1 => To_Unbounded_String ("devices")));
            Muxml.Utils.Add_Child
              (Parent     => Subj_Node,
               Child_Name => "bootparams",
               Ref_Names  => (1 => To_Unbounded_String ("memory")));
            Muxml.Utils.Add_Child
              (Parent     => Subj_Node,
               Child_Name => "channels",
               Ref_Names  => (1 => To_Unbounded_String ("monitor"),
                              2 => To_Unbounded_String ("component")));

            if VCPU_Node = null then
               Muxml.Utils.Add_Child
                 (Parent     => Subj_Node,
                  Child_Name => "vcpu",
                  Ref_Names  => (1 => To_Unbounded_String ("bootparams")));
            end if;
         end;
      end loop;
   end Add_Missing_Elements;

   -------------------------------------------------------------------------

   procedure Add_Mugensched_Idle_Subjects (Data : in out Muxml.XML_Data_Type)
   is
      package Unbounded_Set_Package is new Ada.Containers.Ordered_Sets
        (Element_Type => Unbounded_String);

      Processed : Unbounded_Set_Package.Set;

      Auto_Idle : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/scheduling/partitions/partition/group/subject"
           & "[starts-with(@name,'mugenschedcfg_auto_idle_')]");
      Subjects_Node : constant DOM.Core.Node
        := Muxml.Utils.Get_Element
          (Doc   => Data.Doc,
           XPath => "/system/subjects");
      Count : constant Natural := DOM.Core.Nodes.Length (List => Auto_Idle);
      Ev_Panic_Name : constant String := "idle_panic";
   begin
      if Count > 0 then
         Mulog.Log (Msg => "Adding idle subject(s) for Mugenschedcfg-generated"
                    & " scheduling plan");
         XML_Utils.Create_Physical_Event_Node
           (Policy => Data,
            Name   => Ev_Panic_Name,
            Mode   => "kernel");
         for I in 0 .. DOM.Core.Nodes.Length (List => Auto_Idle) - 1 loop
            declare

               --  Add idle subject with given name.
               procedure Add_Subject (Name : String);

               -------------------------------------------------------------

               procedure Add_Subject (Name : String)
               is
                  N1, N2 : DOM.Core.Node;
               begin
                  N1 := DOM.Core.Documents.Create_Element
                    (Doc      => Data.Doc,
                     Tag_Name => "subject");
                  DOM.Core.Elements.Set_Attribute
                    (Elem  => N1,
                     Name  => "name",
                     Value => Name);
                  DOM.Core.Elements.Set_Attribute
                    (Elem  => N1,
                     Name  => "profile",
                     Value => "native");
                  N1 := DOM.Core.Nodes.Append_Child
                    (N         => Subjects_Node,
                     New_Child => N1);

                  N2 := DOM.Core.Documents.Create_Element
                    (Doc      => Data.Doc,
                     Tag_Name => "vcpu");
                  Muxml.Utils.Append_Child
                    (Node      => N1,
                     New_Child => N2);
                  Mucfgvcpu.Set_VCPU_Profile
                    (Profile => Mucfgvcpu.Native,
                     Node    => N2);

                  Muxml.Utils.Add_Child
                    (Parent     => N1,
                     Child_Name => "bootparams");

                  N2 := DOM.Core.Documents.Create_Element
                    (Doc      => Data.Doc,
                     Tag_Name => "memory");
                  N2 := DOM.Core.Nodes.Append_Child
                    (N         => N1,
                     New_Child => N2);

                  Muxml.Utils.Append_Child
                    (Node      => N2,
                     New_Child => Mutools.XML_Utils.Create_Virtual_Memory_Node
                       (Policy        => Data,
                        Logical_Name  => "stack",
                        Physical_Name => Name & "|stack",
                        Address       => "16#1000#",
                        Writable      => True,
                        Executable    => False));
                  Muxml.Utils.Append_Child
                    (Node      => N2,
                     New_Child => Mutools.XML_Utils.Create_Virtual_Memory_Node
                       (Policy        => Data,
                        Logical_Name  => "text",
                        Physical_Name => Name & "|text",
                        Address       => "16#0020_0000#",
                        Writable      => False,
                        Executable    => True));
                  Muxml.Utils.Append_Child
                    (Node      => N2,
                     New_Child => Mutools.XML_Utils.Create_Virtual_Memory_Node
                       (Policy        => Data,
                        Logical_Name  => "rodata",
                        Physical_Name => Name & "|rodata",
                        Address       => "16#0020_1000#",
                        Writable      => False,
                        Executable    => False));

                  Muxml.Utils.Add_Child
                    (Parent     => N1,
                     Child_Name => "devices");
                  Muxml.Utils.Add_Child
                    (Parent     => N1,
                     Child_Name => "events");
                  declare
                     Default_Ev : constant DOM.Core.Node
                       := DOM.Core.Documents.Create_Element
                         (Doc      => Data.Doc,
                          Tag_Name => "default");
                     Ev_Node : constant DOM.Core.Node
                       := XML_Utils.Add_Optional_Events_Source_Group
                         (Policy  => Data,
                          Subject => N1,
                          Group   => Mutools.Types.Vmx_Exit);
                  begin
                     DOM.Core.Elements.Set_Attribute
                       (Elem  => Default_Ev,
                        Name  => "physical",
                        Value => Ev_Panic_Name);
                     Muxml.Utils.Add_Child
                       (Parent     => Default_Ev,
                        Child_Name => "system_panic");
                     Muxml.Utils.Append_Child (Node      => Ev_Node,
                                               New_Child => Default_Ev);
                  end;
                  Mutools.XML_Utils.Add_Memory_Region
                    (Policy       => Data,
                     Name         => Name & "|stack",
                     Address      => "",
                     Size         => "16#4000#",
                     Caching      => "WB",
                     Alignment    => "16#1000#",
                     Memory_Type  => "subject",
                     Fill_Pattern => "16#00#");
                  Mutools.XML_Utils.Add_Memory_Region
                    (Policy      => Data,
                     Name        => Name & "|text",
                     Address     => "",
                     Size        => "16#1000#",
                     Caching     => "WB",
                     Alignment   => "16#1000#",
                     Memory_Type => "subject_binary",
                     File_Name   => "idle_text",
                     File_Offset => "none");
                  Mutools.XML_Utils.Add_Memory_Region
                    (Policy      => Data,
                     Name        => Name & "|rodata",
                     Address     => "",
                     Size        => "16#1000#",
                     Caching     => "WB",
                     Alignment   => "16#1000#",
                     Memory_Type => "subject_binary",
                     File_Name   => "idle_rodata",
                     File_Offset => "none");
               end Add_Subject;

               Node : constant DOM.Core.Node
                 := DOM.Core.Nodes.Item
                   (List  => Auto_Idle,
                    Index => I);
               Name : constant String
                 := DOM.Core.Elements.Get_Attribute
                   (Elem => Node,
                    Name => "name");
            begin
               if not Processed.Contains (Item => To_Unbounded_String (Name))
               then
                  Add_Subject (Name => Name);
                  Processed.Insert (New_Item => To_Unbounded_String (Name));
               end if;
            end;
         end loop;
      end if;
   end Add_Mugensched_Idle_Subjects;

   -------------------------------------------------------------------------

   procedure Add_Scheduling_Info_Mappings (Data : in out Muxml.XML_Data_Type)
   is
      use type Interfaces.Unsigned_64;

      Sched_Info_Virtual_Address : constant String := Mutools.Utils.To_Hex
        (Number => Config.Subject_Info_Virtual_Addr +
           Expanders.Config.Subject_Sinfo_Region_Size);
      Sched_Info_Virtual_Address_BB : constant String := Mutools.Utils.To_Hex
        (Number => 16#9000_0000# +
           Expanders.Config.Subject_Sinfo_Region_Size);

      Subjects : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject");
      SP_Subjects : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/scheduling/partitions/partition/group/subject");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Subjects) - 1 loop
         declare
            Subject : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Subjects,
                 Index => I);
            Subj_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Subject,
                 Name => "name");
            SP_Subj : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Nodes     => SP_Subjects,
                 Ref_Attr  => "name",
                 Ref_Value => Subj_Name);
            Group_ID_Str : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => DOM.Core.Nodes.Parent_Node (N => SP_Subj),
                 Name => "id");
            Partition_ID_Str : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Muxml.Utils.Ancestor_Node (Node => SP_Subj,
                                                    Level => 2),
                 Name => "id");
            Subj_Mem_Node : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Doc   => Subject,
                 XPath => "memory");
         begin
            Mulog.Log (Msg => "Adding mapping of scheduling "
                       & Partition_ID_Str & " info region to subject '"
                       & Subj_Name & "'");
            DOM.Core.Elements.Set_Attribute
              (Elem  => Subject,
               Name  => "schedGroupId",
               Value => Group_ID_Str);
            Muxml.Utils.Append_Child
              (Node      => Subj_Mem_Node,
               New_Child => Mutools.XML_Utils.Create_Virtual_Memory_Node
                 (Policy        => Data,
                  Logical_Name  => "scheduling_info",
                  Physical_Name => "scheduling_info_"
                  & Partition_ID_Str,
                  Address       => (if Subj_Name = "bb" then
                    Sched_Info_Virtual_Address_BB
                  else
                    Sched_Info_Virtual_Address),
                  Writable      => False,
                  Executable    => False));
         end;
      end loop;
   end Add_Scheduling_Info_Mappings;

   -------------------------------------------------------------------------

   procedure Add_Sibling_Memory (Data : in out Muxml.XML_Data_Type)
   is
      package Cfg renames Expanders.Config;

      Origins : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject[not(sibling)]");
      Sibling_Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject/sibling");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Origins) - 1 loop
         declare
            use type Interfaces.Unsigned_64;

            Origin_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Item (List  => Origins,
                                      Index => I);
            Origin_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Origin_Node,
                 Name => "name");
            Origin_Mem : constant DOM.Core.Node
              := Muxml.Utils.Get_Element (Doc   => Origin_Node,
                                          XPath => "memory");
            Siblings :  constant DOM.Core.Node_List
              := Muxml.Utils.Get_Elements
                (Nodes     => Sibling_Nodes,
                 Ref_Attr  => "ref",
                 Ref_Value => Origin_Name);
            Sibling_Count : constant Natural
              := DOM.Core.Nodes.Length (List => Siblings);
         begin
            for J in 0 .. Sibling_Count - 1 loop
               declare
                  Sibling : constant DOM.Core.Node
                    := DOM.Core.Nodes.Item
                      (List  => Siblings,
                       Index => J);
                  Sib_Subj : constant DOM.Core.Node
                    := DOM.Core.Nodes.Parent_Node (N => Sibling);
                  Sib_Name : constant String
                    := DOM.Core.Elements.Get_Attribute (Elem => Sib_Subj,
                                                        Name => "name");
                  Sib_ID  : constant Interfaces.Unsigned_64
                    := Interfaces.Unsigned_64 (J) + 1;
                  Sib_ID_Str : constant String
                    := Ada.Strings.Fixed.Trim
                      (Source => Sib_ID'Img,
                       Side   => Ada.Strings.Left);
                  Sib_Mem : constant DOM.Core.Node
                    := Muxml.Utils.Get_Element (Doc   => Sib_Subj,
                                                XPath => "memory");
                  Sib_Mems : constant DOM.Core.Node_List
                    := McKae.XML.XPath.XIA.XPath_Query
                      (N     => Sib_Mem,
                       XPath => "memory");
               begin
                  for K in 0 .. DOM.Core.Nodes.Length (List => Sib_Mems) - 1
                  loop
                     declare
                        M : constant DOM.Core.Node := DOM.Core.Nodes.Item
                          (List  => Sib_Mems,
                           Index => K);
                        Logical_Name : constant String
                          := DOM.Core.Elements.Get_Attribute
                            (Elem => M,
                             Name => "logical");
                     begin
                        if Logical_Name = "sinfo" then
                           Mulog.Log (Msg => "Adding sinfo region of sibling '"
                                      & Sib_Name & "' to subject '"
                                      & Origin_Name & "'");
                           DOM.Core.Elements.Set_Attribute
                             (Elem  => M,
                              Name  => "logical",
                              Value => Logical_Name & Sib_ID_Str);

                           --  Set virtual address of sibling sinfo region to
                           --  place it at the expected slot in the consecutive
                           --  array of sinfo regions.

                           DOM.Core.Elements.Set_Attribute
                             (Elem  => M,
                              Name  => "virtualAddress",
                              Value => Mutools.Utils.To_Hex
                                (Number => Config.Subject_Info_Virtual_Addr
                                 + Sib_ID
                                 * (Cfg.Subject_Sinfo_Region_Size
                                   + Cfg.Scheduling_Info_Region_Size)));

                           --  Remove mapping from sibling and add it to origin
                           --  subject.

                           Muxml.Utils.Append_Child
                             (Node      => Origin_Mem,
                              New_Child => DOM.Core.Nodes.Remove_Child
                                (N         => Sib_Mem,
                                 Old_Child => M));
                        elsif Logical_Name = "scheduling_info" then
                           Mulog.Log (Msg => "Adding scheduling partition info "
                                      & "region of sibling '" & Sib_Name
                                      & "' to subject '" & Origin_Name & "'");
                           DOM.Core.Elements.Set_Attribute
                             (Elem  => M,
                              Name  => "logical",
                              Value => Logical_Name & Sib_ID_Str);

                           --  Set virtual address of sibling sched info region
                           --  to place it at the expected slot in the
                           --  consecutive array of sinfo+scheduling_info
                           --  regions. Since scheduling info region is always
                           --  placed right after the sinfo region, the address
                           --  is calculated by calculating the sinfo region
                           --  address of the *next* subject and subtracting the
                           --  sched_info_region size.

                           DOM.Core.Elements.Set_Attribute
                             (Elem  => M,
                              Name  => "virtualAddress",
                              Value => Mutools.Utils.To_Hex
                                (Number => Config.Subject_Info_Virtual_Addr
                                 + (Sib_ID + 1)
                                 * (Cfg.Subject_Sinfo_Region_Size
                                   + Cfg.Scheduling_Info_Region_Size)
                                 - Cfg.Scheduling_Info_Region_Size));

                           --  Remove mapping from sibling and add it to origin
                           --  subject.

                           Muxml.Utils.Append_Child
                             (Node      => Origin_Mem,
                              New_Child => DOM.Core.Nodes.Remove_Child
                                (N         => Sib_Mem,
                                 Old_Child => M));
                        elsif Logical_Name = "timed_event" then
                           Mulog.Log (Msg => "Adding timed event region of "
                                      & "sibling '" & Sib_Name
                                      & "' to subject '" & Origin_Name & "'");
                           DOM.Core.Elements.Set_Attribute
                             (Elem  => M,
                              Name  => "logical",
                              Value => Logical_Name & Sib_ID_Str);

                           --  Set virtual address of sibling timed event region
                           --  to place it at the expected slot in the
                           --  consecutive array of sinfo regions. For systems
                           --  with many siblings the sinfo/sched group info
                           --  mappings may overlap with the timed event virtual
                           --  address. Thus, add an offset to prevent overlap.

                           DOM.Core.Elements.Set_Attribute
                             (Elem  => M,
                              Name  => "virtualAddress",
                              Value => Mutools.Utils.To_Hex
                                (Number =>
                                     Config.Subject_Timed_Event_Virtual_Addr
                                 + Config.Sibling_Timed_Event_Offset
                                 + Sib_ID * MC.Page_Size));
                           Muxml.Utils.Append_Child
                             (Node      => Origin_Mem,
                              New_Child => DOM.Core.Nodes.Remove_Child
                                (N         => Sib_Mem,
                                 Old_Child => M));
                        end if;
                     end;
                  end loop;
               end;
            end loop;

            if Sibling_Count > 0 then
               declare
                  TE_Node : constant DOM.Core.Node
                    := Muxml.Utils.Get_Element
                      (Doc   => Origin_Mem,
                       XPath => "memory[@logical='timed_event']");
               begin
                  Mulog.Log (Msg => "Adjusting timed event region of subject '"
                             & Origin_Name & "'");
                  DOM.Core.Elements.Set_Attribute
                    (Elem  => TE_Node,
                     Name  => "logical",
                     Value => "timed_event0");
                  DOM.Core.Elements.Set_Attribute
                    (Elem  => TE_Node,
                     Name  => "virtualAddress",
                     Value => Mutools.Utils.To_Hex
                       (Number => Config.Subject_Timed_Event_Virtual_Addr
                        + Config.Sibling_Timed_Event_Offset));
               end;
            end if;

            for J in 0 .. Sibling_Count - 1 loop
               declare
                  Sibling : constant DOM.Core.Node
                    := DOM.Core.Nodes.Item
                      (List  => Siblings,
                       Index => J);
                  Sib_Subj : constant DOM.Core.Node
                    := DOM.Core.Nodes.Parent_Node (N => Sibling);
                  Sib_Name : constant String
                    := DOM.Core.Elements.Get_Attribute (Elem => Sib_Subj,
                                                        Name => "name");
                  Sib_Mem : constant DOM.Core.Node
                    := Muxml.Utils.Get_Element (Doc   => Sib_Subj,
                                                XPath => "memory");
                  Old_Mem_Node : DOM.Core.Node;
               begin
                  Mulog.Log (Msg => "Replacing memory of sibling " & Sib_Name
                             & " with origin subject '" & Origin_Name & "'");

                  Old_Mem_Node := DOM.Core.Nodes.Replace_Child
                    (N         => Sib_Subj,
                     New_Child => DOM.Core.Nodes.Clone_Node
                       (N    => Origin_Mem,
                        Deep => True),
                     Old_Child => Sib_Mem);
                  DOM.Core.Nodes.Free (N => Old_Mem_Node);
               end;
            end loop;
         end;
      end loop;
   end Add_Sibling_Memory;

   -------------------------------------------------------------------------

   procedure Add_Sinfo_Regions (Data : in out Muxml.XML_Data_Type)
   is
      Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Nodes) - 1 loop
         declare
            Subj : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Nodes,
                 Index => I);
            Subj_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Subj,
                 Name => "name");
            Subj_Mem_Node : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Doc   => Subj,
                 XPath => "memory");
         begin
            Mulog.Log (Msg => "Adding info region for subject '"
                       & Subj_Name & "'");
            Mutools.XML_Utils.Add_Memory_Region
              (Policy      => Data,
               Name        => Subj_Name & "|sinfo",
               Address     => "",
               Size        => Mutools.Utils.To_Hex
                 (Number => Expanders.Config.Subject_Sinfo_Region_Size),
               Caching     => "WB",
               Alignment   => "16#1000#",
               Memory_Type => "subject_info",
               File_Name   => Subj_Name & "_sinfo",
               File_Offset => "none",
               File_Size   => Mutools.Utils.To_Hex
                 (Number => Expanders.Config.Subject_Sinfo_Region_Size));
            Muxml.Utils.Append_Child
              (Node      => Subj_Mem_Node,
               New_Child => Mutools.XML_Utils.Create_Virtual_Memory_Node
                 (Policy        => Data,
                  Logical_Name  => "sinfo",
                  Physical_Name => Subj_Name & "|sinfo",
                  Address       => (if Subj_Name = "bb" then "16#9000_0000#"
                  else Mutools.Utils.To_Hex
                    (Number => Config.Subject_Info_Virtual_Addr)),
                  Writable      => False,
                  Executable    => False));
         end;
      end loop;
   end Add_Sinfo_Regions;

   -------------------------------------------------------------------------

   procedure Add_Target_Event_IDs  (Data : in out Muxml.XML_Data_Type)
   is
      Subjects  : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject[events/target/event]");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Subjects) - 1 loop
         declare
            Subj_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Subjects,
                 Index => I);
            Subj_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Subj_Node,
                 Name => "name");
            Events_with_IDs : constant DOM.Core.Node_List
              := McKae.XML.XPath.XIA.XPath_Query
                (N     => Subj_Node,
                 XPath => "events/target/event[@id]");
            Events_No_IDs : constant DOM.Core.Node_List
              := McKae.XML.XPath.XIA.XPath_Query
                (N     => Subj_Node,
                 XPath => "events/target/event[not(@id)]");
            ID_Alloc : Utils.Number_Allocator_Type
              (Range_Start => 0,
               Range_End   => 2 ** Mutools.Constants.Event_Bits - 1);
            Cur_ID : Natural;
         begin
            Utils.Reserve_Numbers (Allocator => ID_Alloc,
                                   Nodes     => Events_with_IDs,
                                   Attribute => "id");
            for J in 0 .. DOM.Core.Nodes.Length (List => Events_No_IDs) - 1
            loop
               Utils.Allocate (Allocator => ID_Alloc,
                               Number    => Cur_ID);
               declare
                  Ev_Node : constant DOM.Core.Node
                    := DOM.Core.Nodes.Item
                      (List  => Events_No_IDs,
                       Index => J);
                  Ev_Name :  constant String
                    := DOM.Core.Elements.Get_Attribute
                      (Elem => Ev_Node,
                       Name => "logical");
                  ID_Str  : constant String
                    := Ada.Strings.Fixed.Trim
                      (Source => Cur_ID'Img,
                       Side   => Ada.Strings.Left);
               begin
                  Mulog.Log (Msg => "Setting id of target event '" & Ev_Name
                             & "' of subject '" & Subj_Name & "' to "
                             & ID_Str);
                  DOM.Core.Elements.Set_Attribute
                    (Elem  => Ev_Node,
                     Name  => "id",
                     Value => ID_Str);
               end;
            end loop;
         end;
      end loop;
   end Add_Target_Event_IDs;

   -------------------------------------------------------------------------

   procedure Add_Tau0 (Data : in out Muxml.XML_Data_Type)
   is
   begin
      if not Mutools.XML_Utils.Is_Tau0_Scheduled (Data => Data) then
         Mulog.Log (Msg => "Skipping addition of tau0 subject");
         return;
      end if;

      Mulog.Log (Msg => "Adding tau0 subject");

      declare
         Sched_Tau0    : constant DOM.Core.Node
           := Muxml.Utils.Get_Element
             (Doc   => Data.Doc,
              XPath => "/system/scheduling/partitions/partition/group/"
              & "subject[@name='tau0']");
         Tau0_CPU      : constant String
           := DOM.Core.Elements.Get_Attribute
             (Elem => Muxml.Utils.Ancestor_Node
                (Node  => Sched_Tau0,
                 Level => 2),
              Name => "cpu");
         Subjects_Node : constant DOM.Core.Node
           := Muxml.Utils.Get_Element
             (Doc   => Data.Doc,
              XPath => "/system/subjects");
         Tau0_Node     : DOM.Core.Node
           := DOM.Core.Documents.Create_Element
             (Doc      => Data.Doc,
              Tag_Name => "subject");
         Mem_Node      : constant DOM.Core.Node
           := DOM.Core.Documents.Create_Element
             (Doc      => Data.Doc,
              Tag_Name => "memory");
      begin
         Tau0_Node := DOM.Core.Nodes.Insert_Before
           (N         => Subjects_Node,
            New_Child => Tau0_Node,
            Ref_Child => DOM.Core.Nodes.First_Child (N => Subjects_Node));
         DOM.Core.Elements.Set_Attribute
           (Elem  => Tau0_Node,
            Name  => "globalId",
            Value => "0");
         DOM.Core.Elements.Set_Attribute
           (Elem  => Tau0_Node,
            Name  => "name",
            Value => "tau0");
         DOM.Core.Elements.Set_Attribute
           (Elem  => Tau0_Node,
            Name  => "profile",
            Value => "native");
         DOM.Core.Elements.Set_Attribute
           (Elem  => Tau0_Node,
            Name  => "cpu",
            Value => Tau0_CPU);

         declare
            VCPU_Node : DOM.Core.Node
              := DOM.Core.Documents.Create_Element
                (Doc      => Data.Doc,
                 Tag_Name => "vcpu");
         begin
            Muxml.Utils.Append_Child
              (Node      => Tau0_Node,
               New_Child => VCPU_Node);
            Mucfgvcpu.Set_VCPU_Profile
              (Profile => Mucfgvcpu.Native,
               Node    => VCPU_Node);
         end;

         Muxml.Utils.Append_Child
           (Node      => Tau0_Node,
            New_Child => DOM.Core.Documents.Create_Element
              (Doc      => Data.Doc,
               Tag_Name => "bootparams"));

         Muxml.Utils.Append_Child
           (Node      => Mem_Node,
            New_Child => Mutools.XML_Utils.Create_Virtual_Memory_Node
              (Policy        => Data,
               Logical_Name  => "sys_interface",
               Physical_Name => "sys_interface",
               Address       => Mutools.Utils.To_Hex
                 (Number => Expanders.Config.Tau0_Interface_Virtual_Addr),
               Writable      => True,
               Executable    => False));
         Muxml.Utils.Append_Child
           (Node      => Tau0_Node,
            New_Child => Mem_Node);

         Muxml.Utils.Append_Child
           (Node      => Tau0_Node,
            New_Child => DOM.Core.Documents.Create_Element
              (Doc      => Data.Doc,
               Tag_Name => "devices"));
         Muxml.Utils.Append_Child
           (Node      => Tau0_Node,
            New_Child => DOM.Core.Documents.Create_Element
              (Doc      => Data.Doc,
               Tag_Name => "events"));
         declare
            Default_Ev : constant DOM.Core.Node
              := DOM.Core.Documents.Create_Element
                (Doc      => Data.Doc,
                 Tag_Name => "default");
            Ev_Node : constant DOM.Core.Node
              := XML_Utils.Add_Optional_Events_Source_Group
                (Policy  => Data,
                 Subject => Tau0_Node,
                 Group   => Mutools.Types.Vmx_Exit);
         begin
            DOM.Core.Elements.Set_Attribute
              (Elem  => Default_Ev,
               Name  => "physical",
               Value => "tau0_panic");
            Muxml.Utils.Add_Child
              (Parent     => Default_Ev,
               Child_Name => "system_panic");
            Muxml.Utils.Append_Child (Node      => Ev_Node,
                                      New_Child => Default_Ev);
            XML_Utils.Create_Physical_Event_Node
              (Policy => Data,
               Name   => "tau0_panic",
               Mode   => "kernel");
         end;

         Mutools.XML_Utils.Add_Memory_Region
           (Policy       => Data,
            Name         => "tau0|stack",
            Address      => "",
            Size         => "16#4000#",
            Caching      => "WB",
            Alignment    => "16#1000#",
            Memory_Type  => "subject",
            Fill_Pattern => "16#00#");
         Muxml.Utils.Append_Child
           (Node      => Mem_Node,
            New_Child => Mutools.XML_Utils.Create_Virtual_Memory_Node
              (Policy        => Data,
               Logical_Name  => "stack",
               Physical_Name => "tau0|stack",
               Address       => "16#1000#",
               Writable      => True,
               Executable    => False));
         Mutools.XML_Utils.Add_Memory_Region
           (Policy      => Data,
            Name        => "tau0|bin",
            Address     => "",
            Size        => "16#0001_0000#",
            Caching     => "WB",
            Alignment   => "16#1000#",
            Memory_Type => "subject_binary",
            File_Name   => "tau0",
            File_Offset => "16#001f_f000#");
         Muxml.Utils.Append_Child
           (Node      => Mem_Node,
            New_Child => Mutools.XML_Utils.Create_Virtual_Memory_Node
              (Policy        => Data,
               Logical_Name  => "binary",
               Physical_Name => "tau0|bin",
               Address       => "16#0020_0000#",
               Writable      => True,
               Executable    => True));
      end;
   end Add_Tau0;

   -------------------------------------------------------------------------

   procedure Add_Timed_Event_Mappings (Data : in out Muxml.XML_Data_Type)
   is
      Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Nodes) - 1 loop
         declare
            Subj : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Nodes,
                 Index => I);
            Subj_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Subj,
                 Name => "name");
            Subj_Mem_Node : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Doc   => Subj,
                 XPath => "memory");
         begin
            Mulog.Log (Msg => "Adding timed event page for subject '"
                       & Subj_Name & "'");

            Muxml.Utils.Append_Child
              (Node      => Subj_Mem_Node,
               New_Child => Mutools.XML_Utils.Create_Virtual_Memory_Node
                 (Policy        => Data,
                  Logical_Name  => "timed_event",
                  Physical_Name => Subj_Name & "|timed_event",
                  Address       => (if Subj_Name = "bb" then "16#9001_0000#"
                  else Mutools.Utils.To_Hex
                    (Number => Config.Subject_Timed_Event_Virtual_Addr)),
                  Writable      => True,
                  Executable    => False));
         end;
      end loop;
   end Add_Timed_Event_Mappings;

   -------------------------------------------------------------------------

   procedure Add_Unmask_IRQ_Events (Data : in out Muxml.XML_Data_Type)
   is
      Event_Prefix : constant String := "unmask_irq";

      Phys_Events : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/events/event");
      Unmask_Events : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject/events/source"
           & "/group/*/unmask_irq");
      Phys_IRQs : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/hardware/devices/device"
           & "[pci/@msi='false']/irq");
      Log_Devs : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject/devices/device[irq]");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Phys_IRQs) - 1 loop
         declare
            use type DOM.Core.Node;

            Phys_IRQ : constant DOM.Core.Node
              := DOM.Core.Nodes.Item (List  => Phys_IRQs,
                                      Index => I);
            Phys_IRQ_Nr : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Phys_IRQ,
                 Name => "number");
            Unmask_Ev : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Nodes     => Unmask_Events,
                 Ref_Attr  => "number",
                 Ref_Value => Phys_IRQ_Nr);
         begin
            if Unmask_Ev = null then
               declare
                  Phys_Dev : constant DOM.Core.Node
                    := DOM.Core.Nodes.Parent_Node (N => Phys_IRQ);
                  Phys_Dev_Name : constant String
                    := DOM.Core.Elements.Get_Attribute (Elem => Phys_Dev,
                                                        Name => "name");
                  Phys_IRQ_Name : constant String
                    := DOM.Core.Elements.Get_Attribute (Elem => Phys_IRQ,
                                                        Name => "name");
                  Phys_Ev_Name : constant String := Event_Prefix & Phys_IRQ_Nr;
                  Log_Dev : constant DOM.Core.Node
                    := Muxml.Utils.Get_Element
                      (Nodes     => Log_Devs,
                       Ref_Attr  => "physical",
                       Ref_Value => Phys_Dev_Name);
                  Log_IRQ : constant DOM.Core.Node
                    := (if Log_Dev = null then null
                        else Muxml.Utils.Get_Element
                          (Doc   => Log_Dev,
                           XPath => "irq[@physical='" & Phys_IRQ_Name & "']"));
               begin
                  if Log_IRQ /= null then
                     if Muxml.Utils.Get_Element
                       (Nodes     => Phys_Events,
                        Ref_Attr  => "name",
                        Ref_Value => Phys_Ev_Name) = null
                     then
                        XML_Utils.Create_Physical_Event_Node
                          (Policy => Data,
                           Name   =>  Phys_Ev_Name,
                           Mode   => "kernel");
                     end if;
                     declare
                        Subj : constant DOM.Core.Node
                          := Muxml.Utils.Ancestor_Node (Node  => Log_Dev,
                                                        Level => 2);
                        Subj_Name : constant String
                          := DOM.Core.Elements.Get_Attribute
                            (Elem => Subj,
                             Name => "name");
                        Log_IRQ_Name : constant String
                          := DOM.Core.Elements.Get_Attribute
                            (Elem => Log_IRQ,
                             Name => "logical");
                        Log_Dev_Name : constant String
                          := DOM.Core.Elements.Get_Attribute
                            (Elem => Log_Dev,
                             Name => "logical");
                        Log_IRQ_Vec : constant String
                          := DOM.Core.Elements.Get_Attribute
                            (Elem => Log_IRQ,
                             Name => "vector");
                        Log_Unmask_Ev : constant DOM.Core.Node
                          := XML_Utils.Create_Source_Event_Node
                            (Policy        => Data,
                             ID            => "",
                             Logical_Name  => Event_Prefix & "_" & Log_IRQ_Vec,
                             Physical_Name => Event_Prefix & Phys_IRQ_Nr);
                        Ev_Action : constant DOM.Core.Node
                          := DOM.Core.Documents.Create_Element
                            (Doc      => Data.Doc,
                             Tag_Name => "unmask_irq");
                        Src_Events : DOM.Core.Node
                          := Muxml.Utils.Get_Element
                            (Doc   => Subj,
                             XPath => "events/source/group[@name='vmcall']");
                     begin
                        Mulog.Log (Msg => "Adding unmask IRQ event to subject "
                                   & "'" & Subj_Name & "' for logical"
                                   & " device IRQ " & Log_Dev_Name & "->"
                                   & Log_IRQ_Name);
                        if Src_Events = null then
                           Src_Events
                             := XML_Utils.Add_Optional_Events_Source_Group
                               (Policy  => Data,
                                Subject => Subj,
                                Group   => Mutools.Types.Vmcall);
                        end if;
                        DOM.Core.Elements.Set_Attribute
                          (Elem  => Log_Unmask_Ev,
                           Name  => "id",
                           Value => XML_Utils.Next_Free_Source_Event_ID
                             (Group => Src_Events));
                        DOM.Core.Elements.Set_Attribute
                          (Elem  => Ev_Action,
                           Name  => "number",
                           Value => Phys_IRQ_Nr);
                        Muxml.Utils.Append_Child
                          (Node      => Log_Unmask_Ev,
                           New_Child => Ev_Action);
                        Muxml.Utils.Append_Child
                          (Node      => Src_Events,
                           New_Child => Log_Unmask_Ev);
                     end;
                  end if;
               end;
            end if;
         end;
      end loop;
   end Add_Unmask_IRQ_Events;

   -------------------------------------------------------------------------

   procedure Handle_Loaders (Data : in out Muxml.XML_Data_Type)
   is
      package DCN renames DOM.Core.Nodes;
      package MXU renames Mutools.XML_Utils;

      Memory_Section : constant DOM.Core.Node
        := Muxml.Utils.Get_Element (Doc   => Data.Doc,
                                    XPath => "/system/memory");
      Skip_Mem       : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Memory_Section,
           XPath => "memory[@type='subject_state' or "
           & "@type='subject_timed_event' or @type='subject_interrupts']");
      File_Memory    : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Memory_Section,
           XPath => "memory[file]");
      Subjects       : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject");
      Loader_Subjs   : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject[monitor/loader]");
      Src_Initrd_Mem : DOM.Core.Node_List;
   begin
      for I in 0 .. DCN.Length (List => Loader_Subjs) - 1 loop
         declare
            Ldr_Subj_Node       : constant DOM.Core.Node
              := DCN.Item
                (List  => Loader_Subjs,
                 Index => I);
            Ldr_Subj_Name       : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Ldr_Subj_Node,
                 Name => "name");
            Ldr_Mem_Node        : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Doc   => Ldr_Subj_Node,
                 XPath => "memory");
            Ldr_Node            : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Doc   => Ldr_Subj_Node,
                 XPath => "monitor/loader");
            Ldr_Addr            : constant Interfaces.Unsigned_64
              := Interfaces.Unsigned_64'Value
                (DOM.Core.Elements.Get_Attribute
                     (Elem => Ldr_Node,
                      Name => "virtualAddress"));
            Loadee_Name         : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Ldr_Node,
                 Name => "subject");
            Loadee_Subj         : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Nodes     => Subjects,
                 Ref_Attr  => "name",
                 Ref_Value => Loadee_Name);
            Loadee_Mem_Node     : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Doc   => Loadee_Subj,
                 XPath => "memory");
            Loadee_Mappings     : constant DOM.Core.Node_List
              := McKae.XML.XPath.XIA.XPath_Query
                (N     => Loadee_Mem_Node,
                 XPath => "memory");
            Self_Loader         : constant Boolean
              := Ldr_Subj_Name = Loadee_Name;
            Current_Loader_Addr : Interfaces.Unsigned_64
              := Expanders.Config.Subject_Loader_Source_Base_Addr;
         begin
            for J in 0 .. DCN.Length (List => Loadee_Mappings) - 1 loop
               declare
                  use type Interfaces.Unsigned_64;
                  use type DOM.Core.Node;

                  Map_Node        : constant DOM.Core.Node
                    := DCN.Item (List  => Loadee_Mappings,
                                 Index => J);
                  Map_Log_Name    : constant String
                    := DOM.Core.Elements.Get_Attribute
                      (Elem => Map_Node,
                       Name => "logical");
                  Map_Phys_Name   : constant String
                    := DOM.Core.Elements.Get_Attribute
                      (Elem => Map_Node,
                       Name => "physical");
                  Map_Addr        : constant Interfaces.Unsigned_64
                    := Interfaces.Unsigned_64'Value
                      (DOM.Core.Elements.Get_Attribute
                           (Elem => Map_Node,
                            Name => "virtualAddress"));
                  Map_Is_Writable : constant Boolean
                    := Boolean'Value
                      (DOM.Core.Elements.Get_Attribute
                           (Elem => Map_Node,
                            Name => "writable"));
                  Log_Name        : constant String
                    := Loadee_Name & "_" & Map_Log_Name;
                  Virtual_Addr    : constant String
                    := Mutools.Utils.To_Hex
                      (Number => Ldr_Addr + Map_Addr);
                  Skip            : constant Boolean
                    := Muxml.Utils.Get_Element
                      (Nodes     => Skip_Mem,
                       Ref_Attr  => "name",
                       Ref_Value => Map_Phys_Name) /= null;
                  Loader_Mapping  : constant DOM.Core.Node
                    := (if not Skip then MXU.Create_Virtual_Memory_Node
                        (Policy        => Data,
                         Logical_Name  => Log_Name,
                         Physical_Name => Map_Phys_Name,
                         Address       => Virtual_Addr,
                         Writable      => Map_Is_Writable,
                         Executable    => False)
                        else null);
               begin

                  --  Skip mapping of subject state, timed event and interrupt
                  --  regions in loader, since these are reset by the kernel.

                  if not Skip then

                     --  In case of loading a different subject, a new mapping in
                     --  the loader address space must be added. Furthermore the
                     --  CR4.VMXE flag in the loadee state is cleared to make sure
                     --  a trap occurs after loadee reset. These steps must be
                     --  skipped, when a subject is loading itself.

                     if not Self_Loader then
                        Mulog.Log
                          (Msg => "Mapping memory region '" & Map_Log_Name
                           & "' of subject '" & Loadee_Name & "' "
                           & (if Map_Is_Writable then "writable"
                             else "readable")
                           & " to virtual address " & Virtual_Addr
                           & " of loader subject '" & Ldr_Subj_Name & "'");

                        --  Map region into loader.

                        Muxml.Utils.Append_Child
                          (Node      => Ldr_Mem_Node,
                           New_Child => Loader_Mapping);

                        --  Clear CR4.VMXE in loadee subject state.

                        declare
                           VMXE_Node : constant DOM.Core.Node
                             := Muxml.Utils.Get_Element
                               (Doc   => Loadee_Subj,
                                XPath => "vcpu/registers/cr4/VMXEnable");
                        begin
                           DCN.Normalize (N => VMXE_Node);
                           DCN.Set_Node_Value
                             (N     => DCN.First_Child (N => VMXE_Node),
                              Value => "0");
                        end;
                     end if;

                     --  If writable and file-backed, create physical target
                     --  region and swap original mapping.

                     if Map_Is_Writable then
                        declare
                           Phys_Mem : constant DOM.Core.Node
                             := Muxml.Utils.Get_Element
                               (Nodes     => File_Memory,
                                Ref_Attr  => "name",
                                Ref_Value => Map_Phys_Name);
                           Target_Phys_Name : constant String
                             := Map_Phys_Name  & "_" & Loadee_Name;
                        begin
                           if Phys_Mem /= null then

                              --  Update physical reference(s) to target region.

                              DOM.Core.Elements.Set_Attribute
                                (Elem  => Map_Node,
                                 Name  => "physical",
                                 Value => Target_Phys_Name);
                              DOM.Core.Elements.Set_Attribute
                                (Elem  => Loader_Mapping,
                                 Name  => "physical",
                                 Value => Target_Phys_Name);

                              declare
                                 Phys_Size       : constant String
                                   := DOM.Core.Elements.Get_Attribute
                                     (Elem => Phys_Mem,
                                      Name => "size");
                                 Phys_Type       : constant String
                                   := DOM.Core.Elements.Get_Attribute
                                     (Elem => Phys_Mem,
                                      Name => "type");
                                 Target_Phys_Mem : constant DOM.Core.Node
                                   := MXU.Create_Memory_Node
                                     (Policy      => Data,
                                      Name        => Target_Phys_Name,
                                      Address     => "",
                                      Size        => Phys_Size,
                                      Caching     =>
                                        DOM.Core.Elements.Get_Attribute
                                          (Elem => Phys_Mem,
                                           Name => "caching"),
                                      Alignment   =>
                                        DOM.Core.Elements.Get_Attribute
                                          (Elem => Phys_Mem,
                                           Name => "alignment"),
                                      Memory_Type => Phys_Type);
                                 Hash_Ref        : constant DOM.Core.Node
                                   := DOM.Core.Documents.Create_Element
                                     (Doc      => Data.Doc,
                                      Tag_Name => "hashRef");
                                 Src_Mapping     : constant DOM.Core.Node
                                   := MXU.Create_Virtual_Memory_Node
                                     (Policy        => Data,
                                      Logical_Name  => Log_Name & "_src",
                                      Physical_Name => Map_Phys_Name,
                                      Address       => Mutools.Utils.To_Hex
                                        (Number => Current_Loader_Addr),
                                      Writable      => False,
                                      Executable    => False);
                              begin
                                 Mulog.Log
                                   (Msg => "Swapping file-backed source "
                                    & "region '" & Map_Phys_Name
                                    & "' with target memory region '"
                                    & Target_Phys_Name & "'");

                                 Muxml.Utils.Append_Child
                                   (Node      => DCN.Insert_Before
                                      (N         => Memory_Section,
                                       New_Child => Target_Phys_Mem,
                                       Ref_Child => Phys_Mem),
                                    New_Child => Hash_Ref);
                                 DOM.Core.Elements.Set_Attribute
                                   (Elem  => Hash_Ref,
                                    Name  => "memory",
                                    Value => Map_Phys_Name);

                                 DOM.Core.Elements.Set_Attribute
                                   (Elem  => Phys_Mem,
                                    Name  => "caching",
                                    Value => "WB");

                                 if Phys_Type = "subject_initrd" then

                                    --  Collect all source regions of tybe initrd
                                    --  for post-processing, see below.

                                    DOM.Core.Append_Node
                                      (List => Src_Initrd_Mem,
                                       N    => Phys_Mem);
                                 end if;

                                 --  Add new source mapping to loader.

                                 Muxml.Utils.Append_Child
                                   (Node      => Ldr_Mem_Node,
                                    New_Child => Src_Mapping);

                                 Current_Loader_Addr := Current_Loader_Addr
                                   + Interfaces.Unsigned_64'Value (Phys_Size);
                              end;
                           end if;
                        end;
                     end if;
                  end if;
               end;
            end loop;
         end;
      end loop;

      if DOM.Core.Nodes.Length (List => Src_Initrd_Mem) > 0 then

         --  Retype initrd source memory regions, since conceptually, they are
         --  now just regular memory regions with content that is handled by
         --  loader subjects. Tools (e.g. Mugenzp) only need to consider the
         --  target initrd regions, since those are actually used as initrd
         --  regions by the Linux subjects.
         --  Also, adjusting the memory type of 'subject_initrd' regions has to
         --  be done after all target memory regions have been created, since
         --  the target region type is derived from the potentially shared
         --  initrd source region.

         Mulog.Log (Msg => "Retyping" & DOM.Core.Nodes.Length
                    (List => Src_Initrd_Mem)'Img
                    & "initrd memory regions to 'subject'");
         for I in 0 ..  DOM.Core.Nodes.Length (List => Src_Initrd_Mem) - 1 loop
            DOM.Core.Elements.Set_Attribute
              (Elem  => DOM.Core.Nodes.Item (List  => Src_Initrd_Mem,
                                             Index => I),
               Name  => "type",
               Value => "subject");
         end loop;
      end if;
   end Handle_Loaders;

   -------------------------------------------------------------------------

   procedure Handle_Monitors (Data : in out Muxml.XML_Data_Type)
   is
      Monitor_Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject/monitor");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Monitor_Nodes) - 1 loop
         declare
            Monitor_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Monitor_Nodes,
                 Index => I);
            Subj_Node : constant DOM.Core.Node
              := Muxml.Utils.Ancestor_Node
                (Node  => Monitor_Node,
                 Level => 1);
            Subj_Name : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => Subj_Node,
                 Name => "name");
            Mem_Node : constant DOM.Core.Node
              := Muxml.Utils.Get_Element
                (Doc   => Subj_Node,
                 XPath => "memory");
            Refs : constant DOM.Core.Node_List
              := McKae.XML.XPath.XIA.XPath_Query
                (N     => Monitor_Node,
                 XPath => "*[self::state or self::timed_event "
                 & "or self::interrupts]");
         begin
            for J in 0 .. DOM.Core.Nodes.Length (List => Refs) - 1 loop
               declare
                  Ref_Node : constant DOM.Core.Node
                    := DOM.Core.Nodes.Item
                      (List  => Refs,
                       Index => J);
                  Ref_Type : constant String
                    := DOM.Core.Elements.Get_Tag_Name (Elem => Ref_Node);
                  Monitored_Subj_Name : constant String
                    := DOM.Core.Elements.Get_Attribute
                      (Elem => Ref_Node,
                       Name => "subject");
                  Address : constant String
                    := DOM.Core.Elements.Get_Attribute
                      (Elem => Ref_Node,
                       Name => "virtualAddress");
                  Logical : constant String
                    := DOM.Core.Elements.Get_Attribute
                      (Elem => Ref_Node,
                       Name => "logical");
                  Writable : constant Boolean := Boolean'Value
                    (DOM.Core.Elements.Get_Attribute
                       (Elem => Ref_Node,
                        Name => "writable"));
               begin
                  Mulog.Log (Msg => "Mapping " & Ref_Type & " of subject '"
                             & Monitored_Subj_Name & "' "
                             & (if Writable then "writable" else "readable")
                             & " to virtual address " & Address
                             & " of subject '" & Subj_Name & "'");

                  Muxml.Utils.Append_Child
                    (Node      => Mem_Node,
                     New_Child => Mutools.XML_Utils.Create_Virtual_Memory_Node
                       (Policy        => Data,
                        Logical_Name  => Logical,
                        Physical_Name => Monitored_Subj_Name & "|" & Ref_Type,
                        Address       => Address,
                        Writable      => Writable,
                        Executable    => False));
               end;
            end loop;
         end;
      end loop;
   end Handle_Monitors;

   -------------------------------------------------------------------------

   procedure Handle_Profile (Data : in out Muxml.XML_Data_Type)
   is
      Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Nodes) - 1 loop
         declare
            Subj : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Nodes,
                 Index => I);
            Profile : constant Types.Subject_Profile_Type
              := Types.Subject_Profile_Type'Value
                (DOM.Core.Elements.Get_Attribute
                   (Elem => Subj,
                    Name => "profile"));
         begin
            case Profile is
               when Types.Native => null;
               when Types.VM     => null;
               when Types.Linux  =>
                  Profiles.Handle_Linux_Profile
                    (Data    => Data,
                     Subject => Subj);
            end case;

            DOM.Core.Elements.Remove_Attribute
              (Elem => Subj,
               Name => "profile");
         end;
      end loop;
   end Handle_Profile;

   -------------------------------------------------------------------------

   procedure Merge_Bootparams (Data : in out Muxml.XML_Data_Type)
   is
      Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject[bootparams]");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Nodes) - 1 loop
         declare
            Subj_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Item (List  => Nodes,
                                      Index => I);
            Param_Nodes : constant DOM.Core.Node_List
              := McKae.XML.XPath.XIA.XPath_Query
                (N     => Subj_Node,
                 XPath => "bootparams");
            Param_Count : constant Natural
              := DOM.Core.Nodes.Length (List => Param_Nodes);
         begin
            if Param_Count > 1 then
               Mulog.Log (Msg => "Merging" & Param_Count'Img & " bootparams of"
                          & " subject '" & DOM.Core.Elements.Get_Attribute
                            (Elem => Subj_Node,
                             Name => "name") & "'");
               declare
                  First_Node : constant DOM.Core.Node
                    := DOM.Core.Nodes.Item (List  => Param_Nodes,
                                            Index => 0);
                  Cur_Node   : DOM.Core.Node;
                  Text_Node  : DOM.Core.Node;
                  Param_Str  : Unbounded_String;
               begin
                  for J in reverse 0 .. Param_Count - 1 loop
                     Cur_Node := DOM.Core.Nodes.Item (List  => Param_Nodes,
                                                      Index => J);
                     if DOM.Core.Nodes.Has_Child_Nodes (N => Cur_Node) then
                        DOM.Core.Nodes.Normalize (N => Cur_Node);
                        Text_Node := DOM.Core.Nodes.First_Child
                          (N => Cur_Node);
                        Param_Str := DOM.Core.Nodes.Node_Value (N => Text_Node)
                          & Param_Str;
                     end if;
                     if J /= 0 then
                        Param_Str := " " & Param_Str;
                        Cur_Node := DOM.Core.Nodes.Remove_Child
                          (N         => Subj_Node,
                           Old_Child => Cur_Node);
                        DOM.Core.Nodes.Free (N => Cur_Node);
                     end if;
                  end loop;

                  DOM.Core.Nodes.Set_Node_Value
                    (N     => DOM.Core.Nodes.First_Child (N => First_Node),
                     Value => To_String (Param_Str));
               end;
            end if;
         end;
      end loop;
   end Merge_Bootparams;

   -------------------------------------------------------------------------

   procedure Remove_Channel_Elements (Data : in out Muxml.XML_Data_Type)
   is
      Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject[channels]");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Nodes) - 1 loop
         Muxml.Utils.Remove_Child
           (Node       => DOM.Core.Nodes.Item
              (List  => Nodes,
               Index => I),
            Child_Name => "channels");
      end loop;
   end Remove_Channel_Elements;

   -------------------------------------------------------------------------

   procedure Remove_Device_MSIs (Data : in out Muxml.XML_Data_Type)
   is
   begin
      Muxml.Utils.Remove_Elements
        (Doc   => Data.Doc,
         XPath => "/system/subjects/subject/devices/device/irq[msi]");
   end Remove_Device_MSIs;

   -------------------------------------------------------------------------

   procedure Remove_Monitors (Data : in out Muxml.XML_Data_Type)
   is
      Subjects : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject[monitor]");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => Subjects) - 1 loop
         declare
            Subject_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => Subjects,
                 Index => I);
         begin
            Muxml.Utils.Remove_Child
              (Node       => Subject_Node,
               Child_Name => "monitor");
         end;
      end loop;
   end Remove_Monitors;

end Expanders.Subjects;
