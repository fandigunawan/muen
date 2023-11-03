--
--  Copyright (C) 2014, 2015  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2014, 2015  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with Ada.Strings.Fixed;

with Interfaces;

with McKae.XML.XPath.XIA;

with DOM.Core.Nodes;
with DOM.Core.Documents;
with DOM.Core.Elements;

with Mulog;
with Muxml.Utils;
with Mutools.Constants;
with Mutools.Types;
with Mutools.Utils;
with Mutools.XML_Utils;

with Expanders.Config;
with Expanders.XML_Utils;

package body Expanders.Kernel
is

   package MC renames Mutools.Constants;
   package MX renames Mutools.XML_Utils;

   --  Add mappings of subject memory regions with given type to kernels. If
   --  Executing_CPU is set to True only mappings for subjects running on the
   --  same logical CPU are created. If Check_Physical is set to True, mappings
   --  are only created if the referenced physical memory region exists.
   procedure Add_Subject_Mappings
     (Data           : in out Muxml.XML_Data_Type;
      Base_Address   :        Interfaces.Unsigned_64;
      Size           :        Interfaces.Unsigned_64 := MC.Page_Size;
      Region_Type    :        String;
      Executing_CPU  :        Boolean := True;
      Check_Physical :        Boolean := False);

   -------------------------------------------------------------------------

   procedure Add_Binary_Mappings (Data : in out Muxml.XML_Data_Type)
   is
      CPU_Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/kernel/memory/cpu");
   begin
      Mulog.Log (Msg => "Adding binary memory mappings for"
                 & DOM.Core.Nodes.Length (List => CPU_Nodes)'Img
                 & " kernel(s)");

      for I in 0 .. DOM.Core.Nodes.Length (List => CPU_Nodes) - 1 loop
         declare
            CPU_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => CPU_Nodes,
                 Index => I);
            CPU_Str  : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => CPU_Node,
                 Name => "id");
         begin
            Muxml.Utils.Append_Child
              (Node      => CPU_Node,
               New_Child => MX.Create_Virtual_Memory_Node
                 (Policy        => Data,
                  Logical_Name  => "text",
                  Physical_Name => "kernel_text",
                  Address       => Mutools.Utils.To_Hex
                    (Number => Config.Kernel_Text_Section_Addr),
                  Writable      => False,
                  Executable    => True));
            Muxml.Utils.Append_Child
              (Node      => CPU_Node,
               New_Child => MX.Create_Virtual_Memory_Node
                 (Policy        => Data,
                  Logical_Name  => "data",
                  Physical_Name => "kernel_data_" & CPU_Str,
                  Address       => Mutools.Utils.To_Hex
                    (Number => Config.Kernel_Data_Section_Addr),
                  Writable      => True,
                  Executable    => False));
            Muxml.Utils.Append_Child
              (Node      => CPU_Node,
               New_Child => MX.Create_Virtual_Memory_Node
                 (Policy        => Data,
                  Logical_Name  => "bss",
                  Physical_Name => "kernel_bss_" & CPU_Str,
                  Address       => Mutools.Utils.To_Hex
                    (Number => Config.Kernel_BSS_Section_Addr),
                  Writable      => True,
                  Executable    => False));
            Muxml.Utils.Append_Child
              (Node      => CPU_Node,
               New_Child => MX.Create_Virtual_Memory_Node
                 (Policy        => Data,
                  Logical_Name  => "global_data",
                  Physical_Name => "kernel_global_data",
                  Address       => Mutools.Utils.To_Hex
                    (Number => Config.Kernel_Global_Data_Section_Addr),
                  Writable      => True,
                  Executable    => False));
            Muxml.Utils.Append_Child
              (Node      => CPU_Node,
               New_Child => MX.Create_Virtual_Memory_Node
                 (Policy        => Data,
                  Logical_Name  => "ro",
                  Physical_Name => "kernel_ro",
                  Address       => Mutools.Utils.To_Hex
                    (Number => Config.Kernel_RO_Section_Addr),
                  Writable      => False,
                  Executable    => False));
            Muxml.Utils.Append_Child
              (Node      => CPU_Node,
               New_Child => MX.Create_Virtual_Memory_Node
                 (Policy        => Data,
                  Logical_Name  => "stack",
                  Physical_Name => "kernel_stack_" & CPU_Str,
                  Address       => Mutools.Utils.To_Hex
                    (Number => Config.Kernel_Stack_Addr),
                  Writable      => True,
                  Executable    => False));
            Muxml.Utils.Append_Child
              (Node      => CPU_Node,
               New_Child => MX.Create_Virtual_Memory_Node
                 (Policy        => Data,
                  Logical_Name  => "interrupt_stack",
                  Physical_Name => "kernel_interrupt_stack_" & CPU_Str,
                  Address       => Mutools.Utils.To_Hex
                    (Number => Config.Kernel_Interrupt_Stack_Addr),
                  Writable      => True,
                  Executable    => False));
         end;
      end loop;
   end Add_Binary_Mappings;

   -------------------------------------------------------------------------

   procedure Add_Crash_Audit_Mappings (Data : in out Muxml.XML_Data_Type)
   is
      CPU_Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/kernel/memory/cpu");
      Phys_Node : constant DOM.Core.Node
        := Muxml.Utils.Get_Element
          (Doc   => Data.Doc,
           XPath => "/system/memory/memory[@type='subject_crash_audit']");
      Phys_Name : constant String
        := DOM.Core.Elements.Get_Attribute
          (Elem => Phys_Node,
           Name => "name");
      Addr_Str : constant String
        := Mutools.Utils.To_Hex (Number => Config.Crash_Audit_Virtual_Addr);
   begin
      Mulog.Log (Msg => "Adding crash audit region mappings for"
                 & DOM.Core.Nodes.Length (List => CPU_Nodes)'Img
                 & " kernel(s)");

      for I in 0 .. DOM.Core.Nodes.Length (List => CPU_Nodes) - 1 loop
         Muxml.Utils.Append_Child
           (Node      => DOM.Core.Nodes.Item
              (List  => CPU_Nodes,
               Index => I),
            New_Child => MX.Create_Virtual_Memory_Node
              (Policy        => Data,
               Logical_Name  => "crash_audit",
               Physical_Name => Phys_Name,
               Address       => Addr_Str,
               Writable      => True,
               Executable    => False));
      end loop;
   end Add_Crash_Audit_Mappings;

   -------------------------------------------------------------------------

   procedure Add_Devices (Data : in out Muxml.XML_Data_Type)
   is
      use type Mutools.Types.Kernel_Diagnostics_Kind;

      Debug_Console_Type_Str : constant String
        := Muxml.Utils.Get_Attribute
          (Doc   => Data.Doc,
           XPath => "/system/platform/kernelDiagnostics",
           Name  => "type");
      Debug_Console_Type : constant Mutools.Types.Kernel_Diagnostics_Kind
        := Mutools.Types.Kernel_Diagnostics_Kind'Value
          (Debug_Console_Type_Str);

      --  Base address of kernel device mappings.
      Base_Address : Interfaces.Unsigned_64
        := Config.Kernel_Devices_Virtual_Addr;

      --  Create device reference with given device, MMIO region name and MMIO
      --  address.
      function Create_Device_Reference
        (Device_Logical  : String;
         Device_Physical : String;
         MMIO_Name       : String;
         MMIO_Addr       : String)
         return DOM.Core.Node;

      --  Add mapping for devices of given type identified by specified
      --  capability. The capability string is used as name prefix for logical
      --  device names.
      procedure Add_Device_Mappings
        (Devices_Node : DOM.Core.Node;
         Device_Type  : String;
         Cap_Name     : String);

      --  Add debug console.
      procedure Add_Debug_Console (Devices : DOM.Core.Node);

      --  Add I/O APIC.
      procedure Add_IO_APIC (Devices : DOM.Core.Node);

      --  Add IOMMUs (if present).
      procedure Add_IOMMUs (Devices : DOM.Core.Node);

      --  Add system board.
      procedure Add_System_Board (Devices : DOM.Core.Node);

      ----------------------------------------------------------------------

      procedure Add_Debug_Console (Devices : DOM.Core.Node)
      is
         Kernel_Diag_Dev  : constant DOM.Core.Node
           := Muxml.Utils.Get_Element
             (Doc   => Data.Doc,
              XPath => "/system/platform/kernelDiagnostics/device");
         Phys_Dev_Name    : constant String
           := DOM.Core.Elements.Get_Attribute
             (Elem => Kernel_Diag_Dev,
              Name => "physical");
         Log_Device : constant DOM.Core.Node
           := XML_Utils.Create_Logical_Device_Node
             (Policy        => Data,
              Logical_Name  => "debugconsole",
              Physical_Name => Phys_Dev_Name);
         Dev_Resources : constant DOM.Core.Node_List
           := McKae.XML.XPath.XIA.XPath_Query (N     => Kernel_Diag_Dev,
                                               XPath => "*");
         Dev_Res_Count : constant Natural
           := DOM.Core.Nodes.Length (List => Dev_Resources);

         Port_Count : Natural := 0;
         Mem_Count  : Natural := 0;
      begin
         Mulog.Log (Msg => "Adding physical device '" & Phys_Dev_Name & " as "
                    & Mutools.Utils.Capitalize (Str => Debug_Console_Type_Str)
                    & " debug console to kernel devices");

         for I in 0 .. Dev_Res_Count - 1 loop
            declare
               Dev_Res : constant DOM.Core.Node
                 := DOM.Core.Nodes.Item (List  => Dev_Resources,
                                         Index => I);
               Res_Kind : constant String
                 := DOM.Core.Nodes.Node_Name (N => Dev_Res);
               Phys_Res_Name : constant String
                 := DOM.Core.Elements.Get_Attribute
                   (Elem => Dev_Res,
                    Name => "physical");

               Log_Res : DOM.Core.Node;
            begin
               if Res_Kind = "ioPort" then
                  Log_Res := DOM.Core.Documents.Create_Element
                    (Doc      => Data.Doc,
                     Tag_Name => Res_Kind);
                  DOM.Core.Elements.Set_Attribute
                    (Elem  => Log_Res,
                     Name  => "physical",
                     Value => Phys_Res_Name);
                  DOM.Core.Elements.Set_Attribute
                    (Elem  => Log_Res,
                     Name  => "logical",
                     Value => "port" &
                     (if Port_Count > 0 then Ada.Strings.Fixed.Trim
                            (Source => Port_Count'Img,
                             Side   => Ada.Strings.Left)
                        else ""));
                  Port_Count := Port_Count + 1;
               elsif Res_Kind = "memory" then
                  Log_Res := MX.Create_Virtual_Memory_Node
                    (Policy        => Data,
                     Logical_Name  => "memory" &
                     (if Mem_Count > 0 then Ada.Strings.Fixed.Trim
                            (Source => Mem_Count'Img,
                             Side   => Ada.Strings.Left)
                        else ""),
                     Physical_Name => Phys_Res_Name,
                     Address       => Mutools.Utils.To_Hex
                       (Number => Base_Address),
                     Writable      => True,
                     Executable    => False);

                  declare
                     use type Interfaces.Unsigned_64;

                     Mem_Size : constant Interfaces.Unsigned_64
                       := Interfaces.Unsigned_64'Value
                         (Muxml.Utils.Get_Attribute
                            (Doc   => Data.Doc,
                             XPath => "/system/hardware/devices/device[@name='"
                             & Phys_Dev_Name & "']/memory[@name='"
                             & Phys_Res_Name & "']",
                             Name  => "size"));
                  begin
                     Base_Address := Base_Address + Mem_Size;
                  end;
                  Mem_Count := Mem_Count + 1;
               end if;

               Muxml.Utils.Append_Child
                 (Node      => Log_Device,
                  New_Child => Log_Res);
            end;
         end loop;

         Muxml.Utils.Append_Child
           (Node      => Devices,
            New_Child => Log_Device);
      end Add_Debug_Console;

      ----------------------------------------------------------------------

      procedure Add_Device_Mappings
        (Devices_Node : DOM.Core.Node;
         Device_Type  : String;
         Cap_Name     : String)
      is
         Physical_Devs : constant DOM.Core.Node_List
           := McKae.XML.XPath.XIA.XPath_Query
             (N     => Data.Doc,
              XPath => "/system/hardware/devices/device[capabilities/"
              & "capability/@name='" & Cap_Name & "']");
         Counter       : Positive := 1;
      begin
         for I in 0 .. DOM.Core.Nodes.Length (List => Physical_Devs) - 1 loop
            declare
               use type Interfaces.Unsigned_64;

               Addr_Str : constant String
                 := Mutools.Utils.To_Hex (Number => Base_Address);
               Dev_Node : constant DOM.Core.Node
                 := DOM.Core.Nodes.Item
                   (List  => Physical_Devs,
                    Index => I);
               Dev_Physical : constant String
                 := DOM.Core.Elements.Get_Attribute
                   (Elem => Dev_Node,
                    Name => "name");
               Dev_Logical : constant String
                 := Cap_Name & "_" & Ada.Strings.Fixed.Trim
                   (Source => Counter'Img,
                    Side   => Ada.Strings.Left);
               Mem_Node : constant DOM.Core.Node
                 := Muxml.Utils.Get_Element (Doc   => Dev_Node,
                                             XPath => "memory");
               Mem_Name : constant String
                 := DOM.Core.Elements.Get_Attribute
                   (Elem => Mem_Node,
                    Name => "name");
               Mem_Size : constant Interfaces.Unsigned_64
                 := Interfaces.Unsigned_64'Value
                   (DOM.Core.Elements.Get_Attribute
                      (Elem => Mem_Node,
                       Name => "size"));
            begin
               Mulog.Log (Msg => "Adding " & Device_Type & " '" & Dev_Physical
                          & "' to kernel devices, MMIO: " & Addr_Str);
               Muxml.Utils.Append_Child
                 (Node      => Devices_Node,
                  New_Child => Create_Device_Reference
                    (Device_Logical  => Dev_Logical,
                     Device_Physical => Dev_Physical,
                     MMIO_Name       => Mem_Name,
                     MMIO_Addr       => Addr_Str));

               Base_Address := Base_Address + Mem_Size;
               Counter      := Counter + 1;
            end;
         end loop;
      end Add_Device_Mappings;

      ----------------------------------------------------------------------

      procedure Add_IO_APIC (Devices : DOM.Core.Node)
      is
      begin
         Add_Device_Mappings (Devices_Node => Devices,
                              Device_Type  => "I/O APIC",
                              Cap_Name     => "ioapic");
      end Add_IO_APIC;

      ----------------------------------------------------------------------

      procedure Add_IOMMUs (Devices : DOM.Core.Node)
      is
      begin
         Add_Device_Mappings (Devices_Node => Devices,
                              Device_Type  => "IOMMU",
                              Cap_Name     => "iommu");
      end Add_IOMMUs;

      ----------------------------------------------------------------------

      procedure Add_System_Board (Devices : DOM.Core.Node)
      is
         Phys_Dev : constant DOM.Core.Node
           := Muxml.Utils.Get_Element
             (Doc   => Data.Doc,
              XPath => "/system/hardware/devices/device[capabilities/"
              & "capability/@name='systemboard']");
         Phys_Dev_Name : constant String
           := DOM.Core.Elements.Get_Attribute
             (Elem => Phys_Dev,
              Name => "name");
         Reset_Port : constant DOM.Core.Node
           := Muxml.Utils.Get_Element
             (Doc   => Phys_Dev,
              XPath => "ioPort[@start='16#0cf9#' and @end='16#0cf9#']");
         Poweroff_Port : constant DOM.Core.Node
           := Muxml.Utils.Get_Element
             (Doc   => Phys_Dev,
              XPath => "ioPort[@name='pm1a_cnt']");
         Log_Device : constant DOM.Core.Node
           := XML_Utils.Create_Logical_Device_Node
             (Policy        => Data,
              Logical_Name  => "system_board",
              Physical_Name => Phys_Dev_Name);
      begin
         Mulog.Log (Msg => "Adding system board to kernel devices, physical "
                    & "device '" & Phys_Dev_Name & "'");

         Mutools.XML_Utils.Add_Resource
           (Logical_Device        => Log_Device,
            Physical_Resource     => Reset_Port,
            Logical_Resource_Name => "reset_port");
         Mutools.XML_Utils.Add_Resource
           (Logical_Device        => Log_Device,
            Physical_Resource     => Poweroff_Port,
            Logical_Resource_Name => "poweroff_port");
         Muxml.Utils.Append_Child
           (Node      => Devices,
            New_Child => Log_Device);
      end Add_System_Board;

      ----------------------------------------------------------------------

      function Create_Device_Reference
        (Device_Logical  : String;
         Device_Physical : String;
         MMIO_Name       : String;
         MMIO_Addr       : String)
         return DOM.Core.Node
      is
         Ref : constant DOM.Core.Node
           := XML_Utils.Create_Logical_Device_Node
             (Policy        => Data,
              Logical_Name  => Device_Logical,
              Physical_Name => Device_Physical);
      begin
         Muxml.Utils.Append_Child
           (Node      => Ref,
            New_Child => MX.Create_Virtual_Memory_Node
              (Policy        => Data,
               Logical_Name  => MMIO_Name,
               Physical_Name => MMIO_Name,
               Address       => MMIO_Addr,
               Writable      => True,
               Executable    => False));

         return Ref;
      end Create_Device_Reference;

      Devices_Node : constant DOM.Core.Node
        := Muxml.Utils.Get_Element
          (Doc   => Data.Doc,
           XPath => "/system/kernel/devices");
   begin
      if Debug_Console_Type /= Mutools.Types.None then
         Add_Debug_Console (Devices => Devices_Node);
      end if;
      Add_IO_APIC       (Devices => Devices_Node);
      Add_IOMMUs        (Devices => Devices_Node);
      Add_System_Board  (Devices => Devices_Node);
   end Add_Devices;

   -------------------------------------------------------------------------

   procedure Add_Microcode_Mappings (Data : in out Muxml.XML_Data_Type)
   is
      use type DOM.Core.Node;

      CPU_Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/kernel/memory/cpu");
      Phys_Node : constant DOM.Core.Node
        := Muxml.Utils.Get_Element
          (Doc   => Data.Doc,
           XPath => "/system/memory/memory[@type='kernel_microcode']");
      Addr_Str : constant String
        := Mutools.Utils.To_Hex (Number => Config.Ucode_Virtual_Addr);
   begin
      if Phys_Node = null then
         return;
      end if;
      Mulog.Log (Msg => "Adding microcode region mappings for"
                 & DOM.Core.Nodes.Length (List => CPU_Nodes)'Img
                 & " kernel(s)");

      declare
         Phys_Name : constant String := DOM.Core.Elements.Get_Attribute
             (Elem => Phys_Node,
              Name => "name");
      begin
         for I in 0 .. DOM.Core.Nodes.Length (List => CPU_Nodes) - 1 loop
            Muxml.Utils.Append_Child
              (Node      => DOM.Core.Nodes.Item
                   (List  => CPU_Nodes,
                    Index => I),
               New_Child => MX.Create_Virtual_Memory_Node
                   (Policy        => Data,
                    Logical_Name  => "microcode",
                    Physical_Name => Phys_Name,
                    Address       => Addr_Str,
                    Writable      => False,
                    Executable    => False));
         end loop;
      end;
   end Add_Microcode_Mappings;

   -------------------------------------------------------------------------

   procedure Add_Scheduling_Info_Mappings (Data : in out Muxml.XML_Data_Type)
   is
      CPU_Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/kernel/memory/cpu");
      Sched_Partitions : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/scheduling/partitions/partition");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => CPU_Nodes) - 1 loop
         declare
            CPU_Node : constant DOM.Core.Node
              := DOM.Core.Nodes.Item (List  => CPU_Nodes,
                                      Index => I);
            CPU_ID   : constant String
              := DOM.Core.Elements.Get_Attribute (Elem => CPU_Node,
                                                  Name => "id");
            CPU_SPs  : constant DOM.Core.Node_List
              := Muxml.Utils.Get_Elements
                (Nodes     => Sched_Partitions,
                 Ref_Attr  => "cpu",
                 Ref_Value => CPU_ID);
         begin
            for J in 1 .. DOM.Core.Nodes.Length (List => CPU_SPs) loop
               declare
                  use type Interfaces.Unsigned_64;

                  Cur_SP : constant DOM.Core.Node
                    := DOM.Core.Nodes.Item (List  => CPU_SPs,
                                            Index => J - 1);
                  Cur_SP_ID_Str : constant String
                    := DOM.Core.Elements.Get_Attribute
                      (Elem => Cur_SP,
                       Name => "id");
                  Cur_SP_ID : constant Natural := Natural'Value (Cur_SP_ID_Str);
                  Sched_Info_Name : constant String
                    := "scheduling_info_" & Cur_SP_ID_Str;
                  Virtual_Address : constant Interfaces.Unsigned_64
                    := Config.Scheduling_Info_Virtual_Addr
                      + Interfaces.Unsigned_64
                    (Cur_SP_ID - 1) * Mutools.Constants.Page_Size;
               begin
                  Muxml.Utils.Append_Child
                    (Node      => CPU_Node,
                     New_Child => MX.Create_Virtual_Memory_Node
                       (Policy        => Data,
                        Logical_Name  => Sched_Info_Name,
                        Physical_Name => Sched_Info_Name,
                        Address       => Mutools.Utils.To_Hex
                          (Number => Virtual_Address),
                        Writable      => True,
                        Executable    => False));
               end;
            end loop;
         end;
      end loop;
   end Add_Scheduling_Info_Mappings;

   -------------------------------------------------------------------------

   procedure Add_Section_Skeleton (Data : in out Muxml.XML_Data_Type)
   is
      CPU_Count     : constant Positive
        := MX.Get_Active_CPU_Count (Data => Data);
      Kernel_Node   : constant DOM.Core.Node
        := DOM.Core.Documents.Create_Element
          (Doc      => Data.Doc,
           Tag_Name => "kernel");
      Memory_Node   : constant DOM.Core.Node
        := DOM.Core.Documents.Create_Element
          (Doc      => Data.Doc,
           Tag_Name => "memory");
   begin
      Muxml.Utils.Insert_Before
        (Parent    => DOM.Core.Documents.Get_Element (Doc => Data.Doc),
         New_Child => Kernel_Node,
         Ref_Child => "subjects");

      Muxml.Utils.Append_Child
        (Node      => Kernel_Node,
         New_Child => Memory_Node);
      Muxml.Utils.Append_Child
        (Node      => Kernel_Node,
         New_Child => DOM.Core.Documents.Create_Element
           (Doc      => Data.Doc,
            Tag_Name => "devices"));

      for I in 0 .. CPU_Count - 1 loop
         declare
            CPU_Str  : constant String
              := Ada.Strings.Fixed.Trim
                (Source => I'Img,
                 Side   => Ada.Strings.Left);
            CPU_Node : constant DOM.Core.Node
              := DOM.Core.Documents.Create_Element
                (Doc      => Data.Doc,
                 Tag_Name => "cpu");
         begin
            DOM.Core.Elements.Set_Attribute
              (Elem  => CPU_Node,
               Name  => "id",
               Value => CPU_Str);
            Muxml.Utils.Append_Child
              (Node      => Memory_Node,
               New_Child => CPU_Node);
         end;
      end loop;
   end Add_Section_Skeleton;

   -------------------------------------------------------------------------

   procedure Add_Subj_FPU_State_Mappings (Data : in out Muxml.XML_Data_Type)
   is
   begin
      Add_Subject_Mappings
        (Data         => Data,
         Base_Address => Config.Subject_FPU_States_Virtual_Addr,
         Region_Type  => "fpu");
   end Add_Subj_FPU_State_Mappings;

   -------------------------------------------------------------------------

   procedure Add_Subj_Interrupts_Mappings (Data : in out Muxml.XML_Data_Type)
   is
   begin
      Add_Subject_Mappings
        (Data         => Data,
         Base_Address => Config.Subject_Interrupts_Virtual_Addr,
         Region_Type  => "interrupts");
   end Add_Subj_Interrupts_Mappings;

   -------------------------------------------------------------------------

   procedure Add_Subj_MSR_Store_Mappings (Data : in out Muxml.XML_Data_Type)
   is
   begin
      Add_Subject_Mappings
        (Data           => Data,
         Base_Address   => Config.Subject_MSR_Store_Virtual_Addr,
         Region_Type    => "msrstore",
         Check_Physical => True);
   end Add_Subj_MSR_Store_Mappings;

   -------------------------------------------------------------------------

   procedure Add_Subj_State_Mappings (Data : in out Muxml.XML_Data_Type)
   is
   begin
      Add_Subject_Mappings
        (Data         => Data,
         Base_Address => Config.Subject_States_Virtual_Addr,
         Region_Type  => "state");
   end Add_Subj_State_Mappings;

   -------------------------------------------------------------------------

   procedure Add_Subj_Timed_Event_Mappings (Data : in out Muxml.XML_Data_Type)
   is
   begin
      Add_Subject_Mappings
        (Data         => Data,
         Base_Address => Config.Subject_Timed_Event_Virtual_Addr,
         Region_Type  => "timed_event");
   end Add_Subj_Timed_Event_Mappings;

   -------------------------------------------------------------------------

   procedure Add_Subj_VMCS_Mappings (Data : in out Muxml.XML_Data_Type)
   is
   begin
      Add_Subject_Mappings
        (Data         => Data,
         Base_Address => Config.Subject_VMCS_Virtual_Addr,
         Region_Type  => "vmcs");
   end Add_Subj_VMCS_Mappings;

   -------------------------------------------------------------------------

   procedure Add_Subject_Mappings
     (Data           : in out Muxml.XML_Data_Type;
      Base_Address   :        Interfaces.Unsigned_64;
      Size           :        Interfaces.Unsigned_64 := MC.Page_Size;
      Region_Type    :        String;
      Executing_CPU  :        Boolean := True;
      Check_Physical :        Boolean := False)
   is
      Phys_Mem   : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/memory/memory");
      CPU_Nodes  : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/kernel/memory/cpu");
      Subj_Nodes : constant DOM.Core.Node_List
        := McKae.XML.XPath.XIA.XPath_Query
          (N     => Data.Doc,
           XPath => "/system/subjects/subject");
   begin
      for I in 0 .. DOM.Core.Nodes.Length (List => CPU_Nodes) - 1 loop
         declare
            CPU      : constant DOM.Core.Node
              := DOM.Core.Nodes.Item
                (List  => CPU_Nodes,
                 Index => I);
            CPU_ID   : constant String
              := DOM.Core.Elements.Get_Attribute
                (Elem => CPU,
                 Name => "id");
            Subjects : constant DOM.Core.Node_List
              := (if Executing_CPU then Muxml.Utils.Get_Elements
                  (Nodes     => Subj_Nodes,
                   Ref_Attr  => "cpu",
                   Ref_Value => CPU_ID)
                  else Subj_Nodes);
         begin
            for J in 0 .. DOM.Core.Nodes.Length (List => Subjects) - 1 loop
               declare
                  use type Interfaces.Unsigned_64;
                  use type DOM.Core.Node;

                  Subj      : constant DOM.Core.Node
                    := DOM.Core.Nodes.Item
                      (List  => Subjects,
                       Index => J);
                  Subj_Name : constant String
                    := DOM.Core.Elements.Get_Attribute
                      (Elem => Subj,
                       Name => "name");
                  Subj_ID   : constant String
                    := DOM.Core.Elements.Get_Attribute
                      (Elem => Subj,
                       Name => "globalId");
                  Mem_Name  : constant String
                    := Subj_Name & "|" & Region_Type;
                  Address   : constant Interfaces.Unsigned_64
                    := Base_Address + Interfaces.Unsigned_64'Value (Subj_ID)
                    * Size;
               begin
                  Mulog.Log (Msg => "Mapping " & Region_Type & " of subject '"
                             & Subj_Name & "' to address "
                             & Mutools.Utils.To_Hex
                               (Number => Address) & " on CPU " & CPU_ID);
                  if not Check_Physical
                    or else Muxml.Utils.Get_Element
                      (Nodes     => Phys_Mem,
                       Ref_Attr  => "name",
                       Ref_Value => Mem_Name) /= null
                  then
                     Muxml.Utils.Append_Child
                       (Node      => CPU,
                        New_Child => MX.Create_Virtual_Memory_Node
                          (Policy        => Data,
                           Logical_Name  => Mem_Name,
                           Physical_Name => Mem_Name,
                           Address       => Mutools.Utils.To_Hex
                             (Number => Address),
                           Writable      => True,
                           Executable    => False));
                  end if;
               end;
            end loop;
         end;
      end loop;
   end Add_Subject_Mappings;

   -------------------------------------------------------------------------

   procedure Map_Tau0_Interface (Data : in out Muxml.XML_Data_Type)
   is
      BSP_ID : constant String := Muxml.Utils.Get_Attribute
        (Doc   => Data.Doc,
         XPath => "/system/hardware/processor/cpu[@apicId='0']",
         Name  => "cpuId");
      BSP : constant DOM.Core.Node := Muxml.Utils.Get_Element
        (Doc   => Data.Doc,
         XPath => "/system/kernel/memory/cpu[@id='" & BSP_ID & "']");
   begin
      Mulog.Log (Msg => "Mapping 'tau0' system interface on CPU " & BSP_ID);

      Muxml.Utils.Append_Child
        (Node      => BSP,
         New_Child => MX.Create_Virtual_Memory_Node
           (Policy        => Data,
            Logical_Name  => "tau0_interface",
            Physical_Name => "sys_interface",
            Address       => Mutools.Utils.To_Hex
              (Number => Config.Tau0_Interface_Virtual_Addr),
            Writable      => False,
            Executable    => False));
   end Map_Tau0_Interface;

end Expanders.Kernel;
