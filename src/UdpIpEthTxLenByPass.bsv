import GetPut :: *;
import FIFOF :: *;

import Ports :: *;
import EthUtils :: *;
import MacLayer :: *;
import UdpIpLayer :: *;
import EthernetTypes :: *;
import StreamHandler :: *;
import PortConversion :: *;
import UdpIpLayerForRdma :: *;

import SemiFifo :: *;
import AxiStreamTypes :: *;

interface UdpIpEthTxLenByPass;
   interface FifoOut#(UdpIpMetaData) udpIpMetaDataOut;
endinterface

typedef enum {
    TRANS_TYPE_RC  = 3'h0, // 3'b000
    TRANS_TYPE_UC  = 3'h1, // 3'b001
    TRANS_TYPE_RD  = 3'h2, // 3'b010
    TRANS_TYPE_UD  = 3'h3, // 3'b011
    TRANS_TYPE_CNP = 3'h4, // 3'b100
    TRANS_TYPE_XRC = 3'h5  // 3'b101
} TransType deriving(Bits, Bounded, Eq, FShow);

typedef SizeOf#(TransType) TRANS_TYPE_WIDTH;

typedef enum {
    SEND_FIRST                     = 5'h00,
    SEND_MIDDLE                    = 5'h01,
    SEND_LAST                      = 5'h02,
    SEND_LAST_WITH_IMMEDIATE       = 5'h03,
    SEND_ONLY                      = 5'h04,
    SEND_ONLY_WITH_IMMEDIATE       = 5'h05,
    RDMA_WRITE_FIRST               = 5'h06,
    RDMA_WRITE_MIDDLE              = 5'h07,
    RDMA_WRITE_LAST                = 5'h08,
    RDMA_WRITE_LAST_WITH_IMMEDIATE = 5'h09,
    RDMA_WRITE_ONLY                = 5'h0a,
    RDMA_WRITE_ONLY_WITH_IMMEDIATE = 5'h0b,
    RDMA_READ_REQUEST              = 5'h0c,
    RDMA_READ_RESPONSE_FIRST       = 5'h0d,
    RDMA_READ_RESPONSE_MIDDLE      = 5'h0e,
    RDMA_READ_RESPONSE_LAST        = 5'h0f,
    RDMA_READ_RESPONSE_ONLY        = 5'h10,
    ACKNOWLEDGE                    = 5'h11,
    ATOMIC_ACKNOWLEDGE             = 5'h12,
    COMPARE_SWAP                   = 5'h13,
    FETCH_ADD                      = 5'h14,
    RESYNC                         = 5'h15,
    SEND_LAST_WITH_INVALIDATE      = 5'h16,
    SEND_ONLY_WITH_INVALIDATE      = 5'h17
} RdmaOpCode deriving(Bits, Bounded, Eq, FShow);

typedef SizeOf#(RdmaOpCode) RDMA_OPCODE_WIDTH;

typedef UInt#(UDP_LENGTH_WIDTH) UdpLengthInt;

module mkUdpIpEthTxLenByPass#(
   FifoOut#(DataStream) dataStreamPipeIn,
   FifoOut#(UdpIpMetaData) udpIpMetaDataPipeIn
)(UdpIpEthTxLenByPass);
   FIFOF#(UdpIpMetaData) udpIpMetaDataOutBuf <- mkFIFOF;

   function Tuple2#(TransType, RdmaOpCode) extractTranTypeAndRdmaOpCode(
      Bit#(nSz) inputData
      );
   TransType transType = unpack(inputData[
      valueOf(nSz)-1 :
      valueOf(nSz) - valueOf(TRANS_TYPE_WIDTH)
      ]);
   RdmaOpCode rdmaOpCode = unpack(inputData[
      valueOf(nSz) - valueOf(TRANS_TYPE_WIDTH) - 1 :
      valueOf(nSz) - valueOf(TRANS_TYPE_WIDTH) - valueOf(RDMA_OPCODE_WIDTH)
      ]);

   return tuple2(transType, rdmaOpCode);
   endfunction

   rule getUdpLen;
      let dataStream = dataStreamPipeIn.first;
      dataStreamPipeIn.deq;
      if (dataStream.isFirst) begin
         let {transType, rdmaOpCode} = extractTranTypeAndRdmaOpCode(dataStream.data);
         $display("UDP TransType: ", fshow(transType));
         $display("UDP RDMA OpCode: ", fshow(rdmaOpCode));

         let udpMetaData = udpIpMetaDataPipeIn.first;
         UdpLengthInt currLen = unpack(udpMetaData.dataLen);
         let newLen = currLen;
         if (transType == TRANS_TYPE_RC) begin
            case (rdmaOpCode)
               RDMA_WRITE_ONLY: newLen = currLen + 28;
               RDMA_WRITE_LAST: newLen = currLen + 12;
               RDMA_WRITE_FIRST: newLen = 280;
               RDMA_WRITE_MIDDLE: newLen = 280;
               default: newLen = currLen;
            endcase
         end else begin
                     newLen = currLen;
                  end
         udpMetaData.dataLen = pack(newLen);
         $display("UDP RDMA Len: ", fshow(newLen));
         udpIpMetaDataOutBuf.enq(udpMetaData);
         end
   endrule

   interface udpIpMetaDataOut = convertFifoToFifoOut(udpIpMetaDataOutBuf);

endmodule





