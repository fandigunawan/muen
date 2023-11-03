--
--  Copyright (C) 2015-2020  Reto Buerki <reet@codelabs.ch>
--  Copyright (C) 2015-2020  Adrian-Ken Rueegsegger <ken@codelabs.ch>
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

with SK.UART.State;

package body SK.UART
is

   package Instance is new SK.UART.State;

   -------------------------------------------------------------------------

   procedure Init
   is
   begin

      --  Disable interrupts.

      Write (Address => Base_Address + UART_IER,
             Value   => 0);

      --  Enable DLAB.

      Write (Address => Base_Address + UART_LCR,
             Value   => 16#80#);

      --  Set divisor (least/most significant byte).

      Write (Address => Base_Address + UART_DLL,
             Value   => Divisor);
      Write (Address => Base_Address + UART_DLH,
             Value   => 0);

      --  Clear DLAB and set 8 bits, no parity, one stop bit (8N1).

      Write (Address => Base_Address + UART_LCR,
             Value   => 3);

      --  Enable FIFO.

      Write (Address => Base_Address + UART_FCR,
             Value   => 16#c7#);

      --  Set DTR and RTS.

      Write (Address => Base_Address + UART_MCR,
             Value   => 3);
   end Init;

   -------------------------------------------------------------------------

   function Is_Data_Available return Boolean
   is
      LSR_Data_Ready : constant := 16#01#;

      Data : Register_Type;
   begin
      Read (Address => Base_Address + UART_LSR,
            Value   => Data);
      return (Data and LSR_Data_Ready) /= 0;
   end Is_Data_Available;

   -------------------------------------------------------------------------

   function Is_Send_Buffer_Empty return Boolean
   is
      LSR_Empty_DHR_and_THR : constant := 16#60#;

      Data : Register_Type;
   begin
      Read (Address => Base_Address + UART_LSR,
            Value   => Data);
      return (Data and LSR_Empty_DHR_and_THR) /= 0;
   end Is_Send_Buffer_Empty;

   -------------------------------------------------------------------------

   procedure New_Line
   is
   begin
      Put_Char (Item => ASCII.CR);
      Put_Char (Item => ASCII.LF);
   end New_Line;

   -------------------------------------------------------------------------

   procedure Put_Char (Item : Character)
   is
   begin
      if Instance.Send_Char_Count = FIFO_Size then
         while not Is_Send_Buffer_Empty loop
            null;
         end loop;
         Instance.Send_Char_Count := 0;
      end if;

      Write (Address => Base_Address,
             Value   => Character'Pos (Item));

      Instance.Send_Char_Count := Instance.Send_Char_Count + 1;
   end Put_Char;

   -------------------------------------------------------------------------

   function Read_Char return Character
   is
      Data : Register_Type;
   begin
      Read (Address => Base_Address,
            Value   => Data);
      return Character'Val (Data);
   end Read_Char;

end SK.UART;
