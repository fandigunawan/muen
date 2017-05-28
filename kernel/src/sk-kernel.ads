--
--  Copyright (C) 2013  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2013  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with X86_64;

with SK.CPU_Global;
with SK.FPU;
with SK.Interrupt_Tables;
with SK.IO_Apic;
with SK.MP;
with SK.Scheduling_Info;
with SK.Subjects;
with SK.Subjects_Events;
with SK.Subjects_Interrupts;
with SK.Subjects_MSR_Store;
with SK.Timed_Events;
with SK.VMX;
with SK.Crash_Audit;

package SK.Kernel
is

   --  Kernel initialization.
   procedure Initialize (Subject_Registers : out SK.CPU_Registers_Type)
   with
      Global =>
        (Input  => (CPU_Global.CPU_ID, VMX.Exit_Address,
                    Interrupt_Tables.State),
         Output => CPU_Global.State,
         In_Out => (FPU.State, IO_Apic.State, MP.Barrier, Skp.IOMMU.State,
                    Subjects.State, Scheduling_Info.State,
                    Subjects_Events.State, Subjects_Interrupts.State,
                    Subjects_MSR_Store.State, Timed_Events.State,
                    VMX.VMCS_State, Crash_Audit.State, X86_64.State)),
      Export,
      Convention => C,
      Link_Name  => "sk_initialize";

end SK.Kernel;
