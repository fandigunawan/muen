--
--  Copyright (C) 2014  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2014  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with Muxml;

package Mucfgcheck.Kernel
is
   --D @Section Id => validation-knl, Label => Kernel, Parent => validation
   --D @Text Section => validation-knl
   --D The following kernel-specific checks are performed on the policy.
   --D @UL Id => validators_knl, Section => validation-knl

   --D @Item List => validators_knl
   --D Validate that all CPU-local data section virtual addresses are equal.
   procedure CPU_Local_Data_Address_Equality (XML_Data : Muxml.XML_Data_Type);

   --D @Item List => validators_knl
   --D Validate that all CPU-local BSS section virtual addresses are equal.
   procedure CPU_Local_BSS_Address_Equality (XML_Data : Muxml.XML_Data_Type);

   --D @Item List => validators_knl
   --D Validate that all global data section virtual addresses are equal and
   --D that the expected number of mappings exists.
   procedure Global_Data_Address_Equality (XML_Data : Muxml.XML_Data_Type);

   --D @Item List => validators_knl
   --D Validate that all stack virtual addresses are equal.
   procedure Stack_Address_Equality (XML_Data : Muxml.XML_Data_Type);

   --D @Item List => validators_knl
   --D Validate that all crash audit mappings exist and that their virtual
   --D addresses are equal.
   procedure Crash_Audit_Address_Equality (XML_Data : Muxml.XML_Data_Type);

   --D @Item List => validators_knl
   --D Validate that all (if any) microcode update virtual addresses are equal.
   procedure Microcode_Address_Equality (XML_Data : Muxml.XML_Data_Type);

   --D @Item List => validators_knl
   --D Validate that every kernel has a stack and interrupt stack region mapped
   --D and both regions are guarded by unmapped pages below and above.
   procedure Stack_Layout (XML_Data : Muxml.XML_Data_Type);

   --D @Item List => validators_knl
   --D Validate that all IOMMU memory-mapped IO regions are consecutive.
   procedure IOMMU_Consecutiveness (XML_Data : Muxml.XML_Data_Type);

   --D @Item List => validators_knl
   --D Validate that each active CPU has a memory section.
   procedure CPU_Memory_Section_Count (XML_Data : Muxml.XML_Data_Type);

   --D @Item List => validators_knl
   --D Validate that no virtual memory regions of the kernel overlap.
   procedure Virtual_Memory_Overlap (XML_Data : Muxml.XML_Data_Type);

   --D @Item List => validators_knl
   --D Validate that the system board is referenced in the kernel logical
   --D devices section and that it provides a logical reset port.
   procedure System_Board_Reference (XML_Data : Muxml.XML_Data_Type);

   --D @Item List => validators_knl
   --D Validate that the debug console device and its resources matches the
   --D kernel diagnostics device specified in the platform section.
   procedure Diagnostics_Device_Reference (XML_Data : Muxml.XML_Data_Type);

end Mucfgcheck.Kernel;
