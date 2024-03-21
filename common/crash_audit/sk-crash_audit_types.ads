--
--  Copyright (C) 2017  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2017  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with SK.Exceptions;

--D @Interface
--D This package specifies all data types and records related to the crash audit
--D facility.
package SK.Crash_Audit_Types
is

   type Bit_3_Type is range 0 .. 2 ** 3 - 1
   with
      Size => 3;
   type Bit_4_Type is range 0 .. 2 ** 4 - 1
   with
      Size => 4;
   type Bit_5_Type is range 0 .. 2 ** 5 - 1
   with
      Size => 5;
   type Bit_6_Type is range 0 .. 2 ** 6 - 1
   with
      Size => 6;

   --D @Interface
   --D The magic constant is used to identify the crash audit data structure
   --D and format. It must be adjusted whenever the audit record format is
   --D changed in an incompatible way. The two highest bytes are therefore
   --D used as counter.
   Crash_Magic : constant := 16#0100_0df7_50d5_0e9a#;

   subtype Version_Str_Range is Positive range 1 .. 64;

   --D @Interface
   --D The version string is defined as a fixed-length string of size 64.
   type Version_String_Type is new String (Version_Str_Range)
   with
      Size => Version_Str_Range'Last * 8;

   Null_Version_String : constant Version_String_Type := (others => ASCII.NUL);

   --D @Interface
   --D This constant specifies the maximum number of audit slots which can be
   --D allocated/stored by the crash audit.
   Max_Dumps : constant := 3;

   type Dumpdata_Length is range 0 .. Max_Dumps
   with
      Size => 8;

   subtype Dumpdata_Index is Dumpdata_Length range 1 .. Dumpdata_Length'Last;

   Header_Type_Size : constant := 8 + 64 + (3 * 8) + 4 + 2 + 1 + 1;

   --D @Interface
   --D The crash audit header specifies meta data required for the management
   --D of crash audit data.
   type Header_Type is record
      --D @Interface
      --D Version and format identifier of crash audit data.
      Version_Magic  : Interfaces.Unsigned_64;
      --D @Interface
      --D String representation of version identifier.
      Version_String : Version_String_Type;
      --D @Interface
      --D Generation counter used to identify if crash audit contains active
      --D data, i.e. when Generation = Boot_Count.
      Generation     : Interfaces.Unsigned_64;
      --D @Interface
      --D Number of system boots since last power-off/cold boot.
      Boot_Count     : Interfaces.Unsigned_64;
      --D @Interface
      --D Number of observed crashes record by crash audit.
      Crash_Count    : Interfaces.Unsigned_64;
      --D @Interface
      --D CRC32 checksum (currently unused).
      Crc32          : Interfaces.Unsigned_32;
      Padding        : Interfaces.Unsigned_16;
      --D @Interface
      --D Number of allocated crash audit entries.
      Dump_Count     : Dumpdata_Length'Base;
      --D @Interface
      --D Maximum number of available crash audit entries.
      Max_Dump_Count : Dumpdata_Index'Base;
   end record
   with
      Pack,
      Size => Header_Type_Size * 8;

   Null_Header : constant Header_Type;

   ---------------------
   --  Crash Reasons  --
   ---------------------

   type Reason_Type is new Interfaces.Unsigned_64;

   Reason_Undefined : constant Reason_Type := 16#0000#;

   --  Exceptions.

   Hardware_Exception   : constant Reason_Type := 16#1000#;
   Hardware_VMexit_NMI  : constant Reason_Type := 16#1001#;
   Hardware_VMexit_MCE  : constant Reason_Type := 16#1002#;
   Hardware_VMentry_MCE : constant Reason_Type := 16#1003#;

   --  Subject errors.

   Subj_System_Panic : constant Reason_Type := 16#2000#;
   Subj_Unknown_Trap : constant Reason_Type := 16#2001#;

   --  Init failure.

   System_Init_Failure : constant Reason_Type := 16#3000#;

   --  VT-x errors.

   VTx_VMX_Root_Mode_Failed : constant Reason_Type := 16#4000#;
   VTx_VMX_Vmentry_Failed   : constant Reason_Type := 16#4001#;
   VTx_VMCS_Clear_Failed    : constant Reason_Type := 16#4002#;
   VTx_VMCS_Load_Failed     : constant Reason_Type := 16#4003#;
   VTx_VMCS_Write_Failed    : constant Reason_Type := 16#4004#;
   VTx_VMCS_Read_Failed     : constant Reason_Type := 16#4005#;

   --  VT-d errors.

   VTd_Unable_To_Set_DMAR_Root_Table  : constant Reason_Type := 16#5000#;
   VTd_Unable_To_Invalidate_Ctx_Cache : constant Reason_Type := 16#5001#;
   VTd_Unable_To_Flush_IOTLB          : constant Reason_Type := 16#5002#;
   VTd_Unable_To_Enable_Translation   : constant Reason_Type := 16#5003#;
   VTd_Unable_To_Set_IR_Table         : constant Reason_Type := 16#5004#;
   VTd_Unable_To_Block_CF             : constant Reason_Type := 16#5005#;
   VTd_Unable_To_Enable_IR            : constant Reason_Type := 16#5006#;
   VTd_Unable_To_Disable_QI           : constant Reason_Type := 16#5007#;

   subtype Subj_Reason_Range is Reason_Type range
     Subj_System_Panic .. Subj_Unknown_Trap;

   subtype VTx_Reason_Range is Reason_Type range
     VTx_VMX_Root_Mode_Failed .. VTx_VMCS_Read_Failed;

   subtype VTd_Reason_Range is Reason_Type range
     VTd_Unable_To_Set_DMAR_Root_Table .. VTd_Unable_To_Disable_QI;

   --D @Interface
   --D Bitmap identifying which information contexts contain valid crash
   --D information.
   type Validity_Flags_Type is record
      Ex_Context   : Boolean;
      MCE_Context  : Boolean;
      Subj_Context : Boolean;
      Init_Context : Boolean;
      VTx_Context  : Boolean;
      Padding      : Bit_3_Type;
   end record
   with
      Pack,
      Size => 8;

   Null_Validity_Flags : constant Validity_Flags_Type;

   Ex_Ctx_Size : constant := Exceptions.Isr_Ctx_Size + 3 * 8;

   --D @Interface
   --D Exception execution environment state.
   type Exception_Context_Type is record
      --D @Interface
      --D Interrupt Service Routine execution environment state on exception
      --D occurrence.
      ISR_Ctx       : Exceptions.Isr_Context_Type;
      --D @Interface
      --D Control register values on exception occurrence.
      CR0, CR3, CR4 : Interfaces.Unsigned_64;
   end record
   with
      Pack,
      Size => Ex_Ctx_Size * 8;

   Null_Exception_Context : constant Exception_Context_Type;

   MCE_Max_Banks : constant := 20;

   type Bank_Index_Ext_Range is new Byte range 0 .. MCE_Max_Banks
   with
      Size => 8;

   subtype Bank_Index_Range is Bank_Index_Ext_Range range
     0 .. MCE_Max_Banks - 1;

   type Banks_Array is array (Bank_Index_Range) of Interfaces.Unsigned_64
   with
      Size => MCE_Max_Banks * 8 * 8;

   MCE_Ctx_Size : constant := 8 + 1 + 3 * MCE_Max_Banks * 8;

   --D @Interface
   --D Machine-Check Exception execution environment state.
   type MCE_Context_Type is record
      --D @Interface
      --D Value of Machine-Check global status register on MCE occurrence.
      MCG_Status : Interfaces.Unsigned_64;
      --D @Interface
      --D Number of present MCE reporting banks.
      Bank_Count : Bank_Index_Ext_Range'Base;
      --D @Interface
      --D Status register value for each present MCE bank.
      MCi_Status : Banks_Array;
      --D @Interface
      --D Address of the memory location that produced the MCE for each present
      --D MCE bank.
      MCi_Addr   : Banks_Array;
      --D @Interface
      --D Address of the memory location that produced the MCE for each present
      --D MCE bank.
      MCi_Misc   : Banks_Array;
   end record
   with
      Pack,
      Size => MCE_Ctx_Size * 8;

   Null_MCE_Context : constant MCE_Context_Type;

   type Subj_Ctx_Validity_Flags_Type is record
      Intr_Info       : Boolean;
      Intr_Error_Code : Boolean;
      Padding         : Bit_6_Type;
   end record
   with
      Pack,
      Size => 8;

   Null_Subj_Ctx_Validity_Flags : constant Subj_Ctx_Validity_Flags_Type;

   Subj_Ctx_Size : constant
     := 2 + 1 + 1 + 4 + 4 + Subj_State_Size + XSAVE_Legacy_Header_Size;

   --D @Interface
   --D Subject execution state.
   type Subj_Context_Type is record
      --D @Interface
      --D ID of subject being executed on crash occurrence.
      Subject_ID      : Interfaces.Unsigned_16;
      --D @Interface
      --D Bitmap designating context fields containing valid audit data.
      Field_Validity  : Subj_Ctx_Validity_Flags_Type;
      Padding         : Interfaces.Unsigned_8;
      --D @Interface
      --D Subject interrupt information.
      Intr_Info       : Interfaces.Unsigned_32;
      --D @Interface
      --D Subject interrupt error code.
      Intr_Error_Code : Interfaces.Unsigned_32;
      --D @Interface
      --D Subject state descriptor containing the execution state like register
      --D values etc.
      Descriptor      : Subject_State_Type;
      FPU_Registers   : XSAVE_Legacy_Header_Type;
   end record
   with
      Pack,
      Size => Subj_Ctx_Size * 8;

   Null_Subj_Context : constant Subj_Context_Type;

   type VTx_Ctx_Validity_Flags_Type is record
      Addr_Active_Valid  : Boolean;
      Addr_Request_Valid : Boolean;
      Field_Valid        : Boolean;
      Field_Value_Valid  : Boolean;
      Instrerr_Valid     : Boolean;
      Padding            : Bit_3_Type;
   end record
   with
      Pack,
      Size => 8;

   Null_VTx_Ctx_Validity_Flags : constant VTx_Ctx_Validity_Flags_Type;

   VTx_Ctx_Size : constant := 1 + 3 * 8 + 2 + 1;

   --D @Interface
   --D VT-x execution information.
   type VTx_Context_Type is record
      --D @Interface
      --D Bitmap designating context fields containing valid audit data.
      Field_Validity       : VTx_Ctx_Validity_Flags_Type;
      --D @Interface
      --D Physical address of VMCS that was active on crash occurrence.
      VMCS_Address_Active  : Interfaces.Unsigned_64;
      --D @Interface
      --D Physical address of VMCS that was operated upon on crash occurrence.
      VMCS_Address_Request : Interfaces.Unsigned_64;
      --D @Interface
      --D Identifier of VMCS Field that was operated upon on crash occurrence,
      --D see Intel SDM Vol. 3D, "Appendix B Field Encoding in VMCS".
      VMCS_Field           : Interfaces.Unsigned_16;
      --D @Interface
      --D Value of VMCS Field that was operated upon on crash occurrence.
      VMCS_Field_Value     : Interfaces.Unsigned_64;
      --D @Interface
      --D VM instruction error number, see Intel SDM Vol. 3C,
      --D "30.4 VM Instruction Error Numbers".
      VM_Instr_Error       : Interfaces.Unsigned_8;
   end record
   with
      Pack,
      Size => VTx_Ctx_Size * 8;

   Null_VTx_Context : constant VTx_Context_Type;

   Sys_Init_Ctx_Size : constant := 2;

   --D @Interface
   --D System initialization validity check information.
   type System_Init_Context_Type is record
      --D @Interface
      --D VMX operation supported by hardware.
      VMX_Support             : Boolean;
      --D @Interface
      --D VMX operation enabled or feature control is not locked.
      Not_VMX_Disabled_Locked : Boolean;
      --D @Interface
      --D CPU is in protected mode.
      Protected_Mode          : Boolean;
      --D @Interface
      --D Paging is enabled
      Paging                  : Boolean;
      --D @Interface
      --D CPU is in IA32-e (long) mode.
      IA_32e_Mode             : Boolean;
      --D @Interface
      --D X2Apic supported by hardware.
      Apic_Support            : Boolean;
      --D @Interface
      --D CR0 value is valid for VMX operation on this hardware.
      CR0_Valid               : Boolean;
      --D @Interface
      --D CR4 value is valid for VMX operation on this hardware.
      CR4_Valid               : Boolean;
      --D @Interface
      --D Virtual-8086 mode disabled.
      Not_Virtual_8086        : Boolean;
      --D @Interface
      --D Hardware has Invariant TSC.
      Invariant_TSC           : Boolean;
      Padding                 : Bit_6_Type;
   end record
   with
      Pack,
      Size => Sys_Init_Ctx_Size * 8;

   Null_System_Init_Context : constant System_Init_Context_Type;

   FPU_Init_Ctx_Size : constant := 1;

   --D @Interface
   --D FPU initialization validity check information.
   type FPU_Init_Context_Type is record
      --D @Interface
      --D XSAVE instruction supported by hardware.
      XSAVE_Support : Boolean;
      --D @Interface
      --D XSAVE area fits in subject FPU state memory region.
      Area_Size     : Boolean;
      Padding       : Bit_6_Type;
   end record
   with
      Pack,
      Size => FPU_Init_Ctx_Size * 8;

   Null_FPU_Init_Context : constant FPU_Init_Context_Type;

   MCE_Init_Ctx_Size : constant := 1;

   --D @Interface
   --D Machine-Check exception initialization validity check information.
   type MCE_Init_Context_Type is record
      --D @Interface
      --D Machine-Check Exceptions supported by hardware.
      MCE_Support   : Boolean;
      --D @Interface
      --D Machine-Check Architecture supported by hardware.
      MCA_Support   : Boolean;
      --D @Interface
      --D Number of MCE error reporting banks is supported.
      Bank_Count_OK : Boolean;
      Padding       : Bit_5_Type;
   end record
   with
      Pack,
      Size => MCE_Init_Ctx_Size * 8;

   Null_MCE_Init_Context : constant MCE_Init_Context_Type;

   VTd_IOMMU_Status_Size : constant := 1;

   --D @Interface
   --D VT-d initialization validity check information.
   type VTd_IOMMU_Status_Type is record
      --D @Interface
      --D IOMMU version is supported.
      Version_Support        : Boolean;
      --D @Interface
      --D IOMMU supports a large enough number of domains.
      Nr_Domains_OK          : Boolean;
      --D @Interface
      --D IOMMU actual guest address width is supported.
      AGAW_Support           : Boolean;
      --D @Interface
      --D IOMMU supports interrupt remapping.
      IR_Support             : Boolean;
      --D @Interface
      --D IOMMU supports extended interrupt mode.
      EIM_Support            : Boolean;
      --D @Interface
      --D Number of fault reporting registers matches expected value.
      NFR_Match              : Boolean;
      --D @Interface
      --D Offset of fault reporting registers matches expected value.
      FR_Offset_Match        : Boolean;
      --D @Interface
      --D Offset of IOTLB invalidate register matches expected value.
      IOTLB_Inv_Offset_Match : Boolean;
   end record
   with
      Pack,
      Size => VTd_IOMMU_Status_Size * 8;

   Null_VTd_IOMMU_Status : constant VTd_IOMMU_Status_Type;

   VTd_Max_IOMMU_Status : constant := 8;

   VTd_IOMMU_Status_Array_Size : constant
     := VTd_Max_IOMMU_Status * VTd_IOMMU_Status_Size;

   type VTd_IOMMU_Status_Array is array (1 .. VTd_Max_IOMMU_Status) of
     VTd_IOMMU_Status_Type
   with
      Pack,
      Size => VTd_IOMMU_Status_Array_Size * 8;

   Null_VTd_IOMMU_Status_Array : constant VTd_IOMMU_Status_Array;

   VTd_Init_Context_Type_Size : constant := 1 + VTd_IOMMU_Status_Array_Size;

   --D @Interface
   --D VT-d initialization check information for all present IOMMUs.
   type VTd_Init_Context_Type is record
      --D @Interface
      --D Number of reported IOMMUs.
      IOMMU_Count : Byte;
      --D @Interface
      --D Status of each reported IOMMU.
      Status      : VTd_IOMMU_Status_Array;
   end record
   with
      Pack,
      Size => VTd_Init_Context_Type_Size * 8;

   Null_VTd_Init_Context : constant VTd_Init_Context_Type;

   Init_Ctx_Size : constant
     := (Sys_Init_Ctx_Size + FPU_Init_Ctx_Size
         + MCE_Init_Ctx_Size + VTd_Init_Context_Type_Size);

   --D @Interface
   --D Kernel initialization check information.
   type Init_Context_Type is record
      Sys_Ctx : System_Init_Context_Type;
      FPU_Ctx : FPU_Init_Context_Type;
      MCE_Ctx : MCE_Init_Context_Type;
      VTd_Ctx : VTd_Init_Context_Type;
   end record
   with
      Pack,
      Size => Init_Ctx_Size * 8;

   Null_Init_Context : constant Init_Context_Type;

   Dumpdata_Size : constant := 8 + 8 + 1 + 1 + Ex_Ctx_Size + MCE_Ctx_Size
     + Subj_Ctx_Size + Init_Ctx_Size + VTx_Ctx_Size;

   --D @Interface
   --D The dump data record type specifies a single crash audit entry.
   type Dumpdata_Type is record
      --D @Interface
      --D TSC timestamp when the audit record was written.
      TSC_Value         : Interfaces.Unsigned_64;
      --D @Interface
      --D Reason designating the cause of the crash.
      Reason            : Reason_Type;
      --D @Interface
      --D ID of CPU on which the crash occurred.
      APIC_ID           : Interfaces.Unsigned_8;
      --D @Interface
      --D Bitmap designating which contexts contain further valid data.
      Field_Validity    : Validity_Flags_Type;
      --D @Interface
      --D Audit data related to exception occurrence.
      Exception_Context : Exception_Context_Type;
      --D @Interface
      --D Audit data related to Machine-Check Exception.
      MCE_Context       : MCE_Context_Type;
      --D @Interface
      --D Audit data related to subject, which was executed at the time of the crash.
      Subject_Context   : Subj_Context_Type;
      --D @Interface
      --D Audit data related to system initialization errors.
      Init_Context      : Init_Context_Type;
      --D @Interface
      --D Audit data related to fatal VT-x errors.
      VTx_Context       : VTx_Context_Type;
   end record
   with
      Pack,
      Size => Dumpdata_Size * 8;

   Null_Dumpdata : constant Dumpdata_Type;

   Dumpdata_Array_Size : constant
     := Positive (Dumpdata_Index'Last) * Dumpdata_Size;

   type Dumpdata_Array is array (Dumpdata_Index) of Dumpdata_Type
   with
      Pack,
      Size => Dumpdata_Array_Size * 8;

   Null_Dumpdata_Array : constant Dumpdata_Array;

   Dump_Type_Size : constant := Header_Type_Size + Dumpdata_Array_Size;

   --D @Interface
   --D The dump record type specifies the entire crash audit data structure.
   type Dump_Type is record
      --D @Interface
      --D Audit header containing meta information for the management of the
      --D crash audit data.
      Header : Header_Type;
      --D @Interface
      --D Array of crash audit slots. The header field \texttt{Max\_Dump\_Count}
      --D specifies the array length while \texttt{Dump\_Count} identifies how
      --D many slots are currently filled with audit information.
      Data   : Dumpdata_Array;
   end record
   with
      Pack,
      Size        => Dump_Type_Size * 8,
      Object_Size => Dump_Type_Size * 8;

   Null_Dump : constant Dump_Type;

private

   Null_Header : constant Header_Type
     := (Version_Magic  => Crash_Magic,
         Version_String => Null_Version_String,
         Generation     => 0,
         Boot_Count     => 1,
         Crash_Count    => 0,
         Max_Dump_Count => Max_Dumps,
         Dump_Count     => 0,
         Crc32          => 0,
         Padding        => 0);

   Null_Validity_Flags : constant Validity_Flags_Type
     := (Padding => 0,
         others  => False);

   Null_Exception_Context : constant Exception_Context_Type
     := (ISR_Ctx => Exceptions.Null_Isr_Context,
         others  => 0);

   Null_MCE_Context : constant MCE_Context_Type
     := (MCG_Status => 0,
         Bank_Count => 0,
         others     => (others => 0));

   Null_Subj_Ctx_Validity_Flags : constant Subj_Ctx_Validity_Flags_Type
     := (Intr_Info       => False,
         Intr_Error_Code => False,
         others          => 0);

   Null_Subj_Context : constant Subj_Context_Type
     := (Subject_ID      => 0,
         Field_Validity  => Null_Subj_Ctx_Validity_Flags,
         Padding         => 0,
         Intr_Info       => 0,
         Intr_Error_Code => 0,
         Descriptor      => Null_Subject_State,
         FPU_Registers   => Null_XSAVE_Legacy_Header);

   Null_VTx_Ctx_Validity_Flags : constant VTx_Ctx_Validity_Flags_Type
     := (Padding => 0,
         others  => False);

   Null_VTx_Context : constant VTx_Context_Type
     := (Field_Validity       => Null_VTx_Ctx_Validity_Flags,
         VMCS_Field           => 0,
         VM_Instr_Error       => 0,
         others               => 0);

   Null_System_Init_Context : constant System_Init_Context_Type
     := (Padding => 0,
         others  => False);

   Null_FPU_Init_Context : constant FPU_Init_Context_Type
     := (Padding => 0,
         others  => False);

   Null_MCE_Init_Context : constant MCE_Init_Context_Type
     := (Padding => 0,
         others  => False);

   Null_VTd_IOMMU_Status : constant VTd_IOMMU_Status_Type
     := (others => False);

   Null_VTd_IOMMU_Status_Array : constant VTd_IOMMU_Status_Array
     := (others => Null_VTd_IOMMU_Status);

   Null_VTd_Init_Context : constant VTd_Init_Context_Type
     := (IOMMU_Count => 0,
         Status      => Null_VTd_IOMMU_Status_Array);

   Null_Init_Context : constant Init_Context_Type
     := (Sys_Ctx => Null_System_Init_Context,
         FPU_Ctx => Null_FPU_Init_Context,
         MCE_Ctx => Null_MCE_Init_Context,
         VTd_Ctx => Null_VTd_Init_Context);

   Null_Dumpdata : constant Dumpdata_Type
     := (TSC_Value         => 0,
         APIC_ID           => 0,
         Reason            => Reason_Undefined,
         Field_Validity    => Null_Validity_Flags,
         Exception_Context => Null_Exception_Context,
         MCE_Context       => Null_MCE_Context,
         Subject_Context   => Null_Subj_Context,
         Init_Context      => Null_Init_Context,
         VTx_Context       => Null_VTx_Context);

   Null_Dumpdata_Array : constant Dumpdata_Array
     := (others => Null_Dumpdata);

   Null_Dump : constant Dump_Type
     := (Header => Null_Header,
         Data   => Null_Dumpdata_Array);

end SK.Crash_Audit_Types;
