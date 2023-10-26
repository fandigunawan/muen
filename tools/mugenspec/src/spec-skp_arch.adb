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

with Mulog;
with Muxml.Utils;

with Mutools.Templates;

with String_Templates;

package body Spec.Skp_Arch
is

   -------------------------------------------------------------------------

   procedure Write
     (Output_Dir : String;
      Policy     : Muxml.XML_Data_Type)
   is
      Filename   : constant String := "skp-arch.ads";
      VMXON_Addr : constant Interfaces.Unsigned_64
        := Interfaces.Unsigned_64'Value
          (Muxml.Utils.Get_Attribute
             (Doc   => Policy.Doc,
              XPath => "/system/memory/memory[@type='system_vmxon' and "
              & "contains(string(@name),'kernel_0')]",
              Name  => "physicalAddress"));
      Timer_Rate : constant Natural
        := Natural'Value
          (Muxml.Utils.Get_Attribute
             (Doc   => Policy.Doc,
              XPath => "/system/hardware/processor",
              Name  => "vmxTimerRate"));

      Tmpl : Mutools.Templates.Template_Type;
   begin
      Mulog.Log (Msg => "Writing system spec to '" & Output_Dir & "/"
                 & Filename & "'");

      Tmpl := Mutools.Templates.Create
        (Content => String_Templates.skp_arch_ads);
      Mutools.Templates.Replace
        (Template => Tmpl,
         Pattern  => "__vmxon_addr__",
         Content  => Mutools.Utils.To_Hex (Number => VMXON_Addr));
      Mutools.Templates.Replace
        (Template => Tmpl,
         Pattern  => "__vmx_timer_rate__",
         Content  => Ada.Strings.Fixed.Trim
           (Source => Timer_Rate'Img,
            Side   => Ada.Strings.Left));
      Mutools.Templates.Write
        (Template => Tmpl,
         Filename => Output_Dir & "/" & Filename);
   end Write;

end Spec.Skp_Arch;
