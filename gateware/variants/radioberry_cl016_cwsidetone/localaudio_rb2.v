//
//  AK4951 local audio interface with CW sidetone generator
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
// (C) Takashi Komatsumoto, JI1UDD 2020, 2021

`timescale 1 ns/100 ps

module localaudio_rb2 (
  input          clk,             // 76.8MHz
  input          rst,
// input          clk_i2c_rst,

// input  [31:0]  au_tdata,        // audio L/R tx data (16bit * 2)
// output         au_tready,       // next tx data request
// output [15:0]  au_rdata,        // audio L rx data (16bit)
// output         au_rvalid,       // audio rx data valid

  input          sidetone_sel,    // select sidetone as audio output
  input   [6:0]  profile,         // sidetone profile (7bit)

  input   [5:0]  cmd_addr,        // Command slave interface
  input  [31:0]  cmd_data,
  input          cmd_rqst,

  output         ot_pwm           // pwm(sidetone) i/o pins 

// output         i2s_pdn,         // AK4951 i/o pins (I2S)
// output         i2s_bck,
// output         i2s_lrck,
// output         i2s_mosi,
// input          i2s_miso
) ;

  parameter CLK_FREQ_KHZ = 17'd76800;    // 76800kHz

  wire [15:0] sidetone;
//wire [31:0] audio_tx_data ;

  // -------------------------
  //  Command slave interface
  // -------------------------
  reg [ 7:0] sidetone_vol ;
  reg [11:0] sidetone_freq ;

  always @(posedge clk) begin
    if (cmd_rqst) begin
      case (cmd_addr)
        6'h0f: begin
          sidetone_vol <= cmd_data[23:16] ;
        end

        6'h10: begin
          sidetone_freq <= {cmd_data[15:8],cmd_data[3:0]} ;
        end
      endcase
    end
  end

  // ----------------------
  //  CW sideton generator
  // ----------------------
  cw_sidetone cw_sidetone_i (
    .clk(clk),                    // 76.8MHz
    .tone_enb(sidetone_sel),      // sidetone enable
    .tonefreq(sidetone_freq),     // sidetone audio frequency
    .profile(profile),            // sidetone profile
    .audiovolume(sidetone_vol),   // sidetone audio volume
    .sidetone(sidetone)           // to audio codec
  ) ;


  // -----------------------
  //  PWM-sidetone generator
  // -----------------------
  reg	pwm_o;
  reg [11:0] pwm_cnt;
  reg [11:0] pwm_cmp;
	
  always @(posedge clk) begin
	 if (!sidetone_sel) begin
		pwm_cnt <= 12'h00;
		pwm_cmp <= 12'h00;
		pwm_o <= 1'b0;
    end
	 else begin
		pwm_cnt <= pwm_cnt + 1'b1;
		pwm_cmp <= {!sidetone[13],sidetone[12:2]};
		pwm_o <= (pwm_cnt < pwm_cmp) ? 1'b1 : 1'b0;
	 end
  end
	
  assign ot_pwm  = pwm_o;
	
/*
  // -----------------------
  //  audio output selector
  // -----------------------
  assign audio_tx_data = (sidetone_sel && (sidetone_vol != 8'b0)) ? {sidetone, sidetone} :
                         {au_tdata[7:0],au_tdata[15:8],au_tdata[23:16],au_tdata[31:24]} ;


  // -----------------------
  //  AK4951 interface
  // -----------------------
  assign i2s_pdn  = ~clk_i2c_rst;   // AK4951 PDN ; active "L"

  i2s_ak4951 i2s_i (
    .clk(clk),
    .tx_data(audio_tx_data),      // audio L/R tx data (16bit * 2)
    .tx_data_req(au_tready),      // next tx data request
    .rx_data(au_rdata),           // audio L rx data (16bit)
    .rx_data_valid(au_rvalid),    // audio rx data valid
    .i2s_bck(i2s_bck),
    .i2s_lrck(i2s_lrck),
    .i2s_mosi(i2s_mosi),
    .i2s_miso(i2s_miso)
 ) ;
*/

endmodule