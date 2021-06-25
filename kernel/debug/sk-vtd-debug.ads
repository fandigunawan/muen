--
--  Copyright (C) 2021  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2021  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with Skp.IOMMU;

package SK.VTd.Debug
is

   --  Process fault reported by IOMMU.
   procedure Process_Fault
   with
      Global => (In_Out => Skp.IOMMU.State);

   --  Sets the fault interrupt vector and destination APIC ID of the specified
   --  IOMMU to the given values.
   procedure Setup_Fault_Interrupt
     (IOMMU  : Skp.IOMMU.IOMMU_Device_Range;
      Vector : SK.Byte)
   with
      Global  => (In_Out => Skp.IOMMU.State),
      Depends => (Skp.IOMMU.State =>+ (IOMMU, Vector));

end SK.VTd.Debug;
